#!/usr/bin/env bash
# Despliega una versión en un entorno.
# Uso: deploy.sh <uat|prod> <api|web|ambos> <sha-api-o-web> [<sha-web>]
#   deploy.sh uat api 3f2a...        solo cambia la api
#   deploy.sh uat web 9c1d...        solo cambia la web
#   deploy.sh prod ambos <api> <web> promoción a prod
# En prod hace pg_dump a S3 antes. Si el healthcheck, el digest o el smoke test fallan, vuelve atrás.
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
componente="${2:-}"
validar_entorno "$entorno"
cargar_host

dir="$KONOHA_DIR/$entorno"
version="$dir/version.env"
mkdir -p "$dir"

exec 9>"$dir/.deploy.lock"
flock -n 9 || error "Ya hay un despliegue en curso en $entorno."

api_actual=""
web_actual=""
if [[ -f "$version" ]]; then
  api_actual="$(leer_version "$version" API_SHA)"
  web_actual="$(leer_version "$version" WEB_SHA)"
fi
api_nueva="$api_actual"
web_nueva="$web_actual"

case "$componente" in
  api) api_nueva="${3:?Falta el SHA de la api}" ;;
  web) web_nueva="${3:?Falta el SHA de la web}" ;;
  ambos)
    api_nueva="${3:?Falta el SHA de la api}"
    web_nueva="${4:?Falta el SHA de la web}"
    ;;
  *) error "Componente no válido: '$componente'. Usa api, web o ambos." ;;
esac
[[ -n "$api_nueva" && -n "$web_nueva" ]] || error "Falta la versión de api o de web: el primer despliegue de $entorno tiene que ser 'ambos'."

registro="${REGISTRO_IMAGENES:?Falta REGISTRO_IMAGENES en host.env}"
log "Despliegue en $entorno: api $api_actual -> $api_nueva, web $web_actual -> $web_nueva"

if [[ "${SIN_PULL:-0}" != "1" ]]; then
  if [[ -n "${GHCR_TOKEN_LECTURA:-}" ]]; then
    printf '%s' "$GHCR_TOKEN_LECTURA" | docker login ghcr.io -u "${GHCR_USUARIO:?Falta GHCR_USUARIO}" --password-stdin >/dev/null
  fi
  docker pull -q "$registro/konoha-api:$api_nueva" >/dev/null
  docker pull -q "$registro/konoha-web:$web_nueva" >/dev/null
fi

if [[ "$entorno" == "prod" && "${SIN_BACKUP:-0}" != "1" ]]; then
  "$(dirname "$0")/backup.sh" prod || error "El backup previo ha fallado: no se despliega sin backup."
fi

if [[ -f "$version" ]]; then cp "$version" "$dir/version.env.anterior"; fi
cat > "$version" <<VERSION
REGISTRO_IMAGENES=$registro
API_SHA=$api_nueva
WEB_SHA=$web_nueva
DESPLEGADO_EN=$(date -Iseconds)
VERSION

fallo() {
  log "Fallo en el despliegue de $entorno: $1"
  avisar_fallo "Despliegue fallido en $entorno ($1). api=$api_nueva web=$web_nueva. Se vuelve a la versión anterior."
  if [[ -f "$dir/version.env.anterior" ]]; then
    "$(dirname "$0")/volver-atras.sh" "$entorno" || log "La vuelta atrás también ha fallado: revisa a mano."
  fi
  exit 1
}

compose "$entorno" up -d --remove-orphans --wait --wait-timeout 300 || fallo "los contenedores no quedan sanos"
"$(dirname "$0")/verificar-digest.sh" "$entorno" || fallo "el contenedor no corre la imagen esperada"
"$(dirname "$0")/smoke-test.sh" "$entorno" || fallo "el smoke test no pasa"

# Historial de despliegues correctos: promover-prod.yml solo acepta versiones que han pasado por UAT.
printf '%s api=%s web=%s\n' "$(date -Iseconds)" "$api_nueva" "$web_nueva" >> "$dir/historial"
log "Despliegue en $entorno correcto."
