#!/usr/bin/env bash
# Comprueba que cada archivo que la base referencia (core_archivo.clave y mod05_archivo.ruta_almacenamiento)
# existe en el volumen de adjuntos y que su SHA-256 coincide con hash_contenido.
# Uso: comprobar-referencias.sh <contenedor-db> <volumen-adjuntos>
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

db="${1:?Falta el contenedor de la base}"
volumen="${2:?Falta el volumen de adjuntos}"
imagen="$(docker inspect -f '{{.Config.Image}}' "$db")"

consulta="select clave || '|' || hash_contenido from core_archivo
  union all select ruta_almacenamiento || '|' || hash_contenido from mod05_archivo"
referencias="$(docker exec "$db" psql -U konoha -d konoha -Atc "$consulta")"
total="$(grep -c . <<< "$referencias" || true)"

# shellcheck disable=SC2016  # el script va entre comillas simples: lo expande el contenedor
docker run --rm -i -v "$volumen":/datos:ro --entrypoint sh "$imagen" -c '
  malos=0
  while IFS="|" read -r clave hash; do
    f="/datos/$clave"
    if [ ! -f "$f" ]; then echo "AUSENTE: $clave"; malos=$((malos + 1))
    elif [ "$(sha256sum "$f" | cut -d" " -f1)" != "$hash" ]; then echo "HASH DISTINTO: $clave"; malos=$((malos + 1)); fi
  done
  [ "$malos" -eq 0 ]' <<< "$referencias" || error "Hay referencias de la base que no resuelven a un archivo íntegro."
log "Referencias correctas: $total archivos de la base resuelven en $volumen con su hash."
