#!/usr/bin/env bash
# Restaura un respaldo conjunto en un entorno de prueba aislado (base y volumen temporales, sin red ni
# puertos publicados) y comprueba las referencias. No toca el entorno real. Se borra todo al terminar.
# Uso: probar-restauracion.sh <uat|prod> <backups/<entorno>/<fecha>>
# Imagen de la base: POSTGIS_IMAGEN (por defecto, la del contenedor <entorno>-db).
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
clave="${2:?Falta la clave del respaldo (backups/<entorno>/<fecha>)}"
validar_entorno "$entorno"
cargar_host
[[ "$clave" == backups/"$entorno"/* ]] || error "La clave $clave no es de $entorno."

id="prueba-restauracion-$$"
tmp="$(mktemp -d "${BACKUP_TMP:-/var/tmp}/$id.XXXXXX")"
limpiar() { docker rm -f "$id" >/dev/null 2>&1 || true; docker volume rm "$id" >/dev/null 2>&1 || true; rm -rf "$tmp"; }
trap limpiar EXIT

descargar_backup "$clave" "$tmp"
"$(dirname "$0")/verificar-backup.sh" "$tmp" "$entorno"

imagen="${POSTGIS_IMAGEN:-$(docker inspect -f '{{.Config.Image}}' "$(compose "$entorno" ps -q "$entorno-db")")}"
docker volume create "$id" >/dev/null
docker run -d --name "$id" --network none -e POSTGRES_USER=konoha -e POSTGRES_DB=konoha \
  -e POSTGRES_HOST_AUTH_METHOD=trust "$imagen" >/dev/null
# Por TCP: el servidor temporal de la inicialización solo escucha en el socket.
until docker exec "$id" pg_isready -h 127.0.0.1 -U konoha -d konoha >/dev/null 2>&1; do sleep 1; done

docker exec -i "$id" pg_restore -U konoha -d konoha --clean --if-exists --no-owner < "$tmp/db.dump"
docker run --rm -i -v "$id":/datos --entrypoint tar "$imagen" -C /datos -xzf - < "$tmp/adjuntos.tar.gz"
"$(dirname "$0")/comprobar-referencias.sh" "$id" "$id"
log "Prueba de restauración de $clave superada."
