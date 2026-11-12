#!/usr/bin/env bash
# Respaldo conjunto de un entorno: base de datos (pg_dump) y adjuntos (volumen archivos).
# Uso: backup.sh <uat|prod>
# Destino: s3://<bucket>/backups/<entorno>/<fecha>/ o, con BACKUP_DESTINO_LOCAL, ese directorio (pruebas sin S3).
# Un respaldo son 4 ficheros: db.dump, adjuntos.tar.gz, SHA256SUMS y manifiesto.env. El manifiesto se sube
# el último: sin él, o con estado distinto de "completo", el respaldo no existe (verificar-backup.sh).
# Variables de prueba: DB_CONTENEDOR, ADJUNTOS_VOLUMEN, BACKUP_TMP (carpeta de trabajo, por defecto /var/tmp).
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
validar_entorno "$entorno"
cargar_host

contenedor="${DB_CONTENEDOR:-$(compose "$entorno" ps -q "$entorno-db" 2>/dev/null || true)}"
# Solo vale en el primer despliegue de prod, cuando aún no hay base. En ningún caso cuenta como respaldo.
[[ -n "$contenedor" ]] || { log "Backup: $entorno-db no está corriendo. NO se ha generado ningún respaldo."; exit 0; }
volumen="${ADJUNTOS_VOLUMEN:-konoha-${entorno}_archivos}"
imagen="$(docker inspect -f '{{.Config.Image}}' "$contenedor")" # ya está en el host: no se descarga nada
fecha="$(date '+%Y%m%dT%H%M%S')"
destino="backups/$entorno/$fecha"
aws_cli() { docker run --rm -i -e AWS_REGION="${AWS_REGION:-us-east-1}" "$@"; }

tmp="$(mktemp -d "${BACKUP_TMP:-/var/tmp}/konoha-backup.XXXXXX")"
terminado=0
al_salir() {
  local rc=$?
  rm -rf "$tmp"
  (( terminado )) || log "ERROR: backup de $entorno FALLIDO (código $rc). NO hay respaldo completo de $entorno/$fecha."
}
trap al_salir EXIT

# Espacio: la base y los adjuntos se preparan en disco local antes de subirlos.
docker volume inspect "$volumen" >/dev/null 2>&1 || error "No existe el volumen de adjuntos $volumen."
{ read -r n_adjuntos; read -r kb_adjuntos; } < <(docker run --rm -v "$volumen":/datos:ro --entrypoint sh "$imagen" \
  -c 'find /datos -type f | wc -l; du -sk /datos | cut -f1')
n_adjuntos="${n_adjuntos// /}"
bytes_db="$(docker exec "$contenedor" psql -U konoha -d konoha -Atc 'select pg_database_size(current_database())')"
necesario_kb=$(( bytes_db / 1024 + kb_adjuntos + 102400 ))
libre_kb="$(df -Pk "$tmp" | awk 'NR==2 {print $4}')"
(( libre_kb > necesario_kb )) || error "Espacio insuficiente en $tmp: hay ${libre_kb} KB y hacen falta ${necesario_kb} KB."
log "Backup de $entorno ($fecha): base $((bytes_db / 1048576)) MB; adjuntos $n_adjuntos ficheros, $((kb_adjuntos / 1024)) MB."

docker exec "$contenedor" pg_dump -U konoha -d konoha -Fc > "$tmp/db.dump"
docker run --rm -v "$volumen":/datos:ro --entrypoint tar "$imagen" -C /datos -czf - . > "$tmp/adjuntos.tar.gz"
(cd "$tmp" && "${SHA256[@]}" db.dump adjuntos.tar.gz > SHA256SUMS)
cat > "$tmp/manifiesto.env" <<MANIFIESTO
version=1
entorno=$entorno
fecha=$fecha
anfitrion=$(hostname)
adjuntos_ficheros=$n_adjuntos
estado=completo
MANIFIESTO
"$(dirname "$0")/verificar-backup.sh" "$tmp" "$entorno" >&2

if [[ -n "${BACKUP_DESTINO_LOCAL:-}" ]]; then
  mkdir -p "$BACKUP_DESTINO_LOCAL/$destino"
  cp "$tmp/db.dump" "$tmp/adjuntos.tar.gz" "$tmp/SHA256SUMS" "$BACKUP_DESTINO_LOCAL/$destino/"
  cp "$tmp/manifiesto.env" "$BACKUP_DESTINO_LOCAL/$destino/"
  "$(dirname "$0")/verificar-backup.sh" "$BACKUP_DESTINO_LOCAL/$destino" "$entorno" >&2
else
  uri="s3://${BUCKET:?Falta BUCKET}/$destino/"
  # Las credenciales salen del perfil de la instancia (LabInstanceProfile).
  aws_cli -v "$tmp":/b:ro amazon/aws-cli:2.22.35 s3 cp /b "$uri" --recursive --exclude manifiesto.env --only-show-errors
  aws_cli -v "$tmp":/b:ro amazon/aws-cli:2.22.35 s3 cp /b/manifiesto.env "$uri" --only-show-errors
fi
terminado=1
log "Backup de $entorno terminado: $destino"
