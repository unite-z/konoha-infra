#!/usr/bin/env bash
# Comprueba que los contenedores de un entorno corren exactamente las imágenes de version.env.
# Uso: verificar-digest.sh <uat|prod>
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
validar_entorno "$entorno"
version="$KONOHA_DIR/$entorno/version.env"
registro="$(leer_version "$version" REGISTRO_IMAGENES)"
errores=0

for componente in api web; do
  clave="$(tr '[:lower:]' '[:upper:]' <<< "$componente")_SHA"
  imagen="$registro/konoha-$componente:$(leer_version "$version" "$clave")"
  contenedor="$(compose "$entorno" ps -q "$entorno-$componente")"
  [[ -n "$contenedor" ]] || { log "$entorno-$componente no está corriendo."; errores=1; continue; }
  esperado="$(docker image inspect --format '{{.Id}}' "$imagen")"
  real="$(docker inspect --format '{{.Image}}' "$contenedor")"
  if [[ "$esperado" == "$real" ]]; then
    log "$entorno-$componente corre $imagen ($esperado)."
  else
    log "$entorno-$componente corre $real, pero se esperaba $imagen ($esperado)."
    errores=1
  fi
done

exit "$errores"
