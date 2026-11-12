#!/usr/bin/env bash
# Restaura un respaldo conjunto (base y adjuntos) en un entorno. Destructivo: sustituye la base y los adjuntos.
# Uso: restaurar-backup.sh <uat|prod> <backups/<entorno>/<fecha>>
#   restaurar-backup.sh prod backups/prod/20261022T130000
# Antes, ensayo aislado y sin tocar nada: probar-restauracion.sh <entorno> <clave>.
# Nunca restaures un backup de prod en uat sin reescribir las claves de S3 (almacenamiento.md del backend).
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
clave="${2:?Falta la clave del respaldo en S3}"
validar_entorno "$entorno"
cargar_host

if [[ "$clave" != backups/"$entorno"/* ]]; then
  error "La clave $clave no es de $entorno. Restaurar entre entornos exige reescribir las claves de S3: hazlo a mano siguiendo el runbook."
fi
[[ "$clave" != *.dump ]] || error "Formato antiguo (solo base): restáurala a mano con el runbook. Los respaldos nuevos son un directorio."

tmp="$(mktemp -d "${BACKUP_TMP:-/var/tmp}/restaurar.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
# Se descarga y se verifica antes de pedir confirmación ni parar nada: un respaldo malo no toca el entorno.
descargar_backup "$clave" "$tmp"
"$(dirname "$0")/verificar-backup.sh" "$tmp" "$entorno"

read -r -p "Se van a sustituir la base y los adjuntos de $entorno por $clave. Escribe '$entorno' para continuar: " confirmacion
[[ "$confirmacion" == "$entorno" ]] || error "Cancelado."

"$(dirname "$0")/backup.sh" "$entorno"
compose "$entorno" stop "$entorno-api"
contenedor="$(compose "$entorno" ps -q "$entorno-db")"
volumen="${ADJUNTOS_VOLUMEN:-konoha-${entorno}_archivos}"
imagen="$(docker inspect -f '{{.Config.Image}}' "$contenedor")"
docker exec -i "$contenedor" pg_restore -U konoha -d konoha --clean --if-exists --no-owner < "$tmp/db.dump"
docker run --rm -i -v "$volumen":/datos --entrypoint sh "$imagen" \
  -c 'find /datos -mindepth 1 -delete && tar -C /datos -xzf -' < "$tmp/adjuntos.tar.gz"
"$(dirname "$0")/comprobar-referencias.sh" "$contenedor" "$volumen"
compose "$entorno" start "$entorno-api"
compose "$entorno" up -d --wait --wait-timeout 300
"$(dirname "$0")/smoke-test.sh" "$entorno"
log "Restauración de $entorno terminada."
