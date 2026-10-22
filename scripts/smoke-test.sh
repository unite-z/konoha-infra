#!/usr/bin/env bash
# Comprobación rápida de un entorno tras desplegar: health de la api, la PWA y, si hay usuario de prueba, un GET autenticado.
# Uso: smoke-test.sh <uat|prod>
# Por defecto entra por la red interna de Docker. Con SMOKE_URL=https://... prueba desde fuera (a través del borde).
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
validar_entorno "$entorno"
cargar_host

# curl desde un contenedor en la red del borde: no depende del DNS ni del certificado.
pedir() {
  docker run --rm --network konoha-edge curlimages/curl:8.11.1 -fsS -m 10 "$@"
}

api="${SMOKE_URL:-http://$entorno-api:8000}"
web="${SMOKE_URL:-http://$entorno-web:8080}"

estado="$(pedir "$api/api/health")" || { log "Smoke: /api/health no responde."; exit 1; }
[[ "$estado" == *'"UP"'* ]] || { log "Smoke: /api/health responde $estado."; exit 1; }
log "Smoke: api UP."

pedir "$web/" | grep -q '<div id="root">' || { log "Smoke: la PWA no devuelve index.html."; exit 1; }
log "Smoke: web sirve la PWA."

if [[ -n "${SMOKE_USUARIO:-}" && -n "${SMOKE_CLAVE:-}" ]]; then
  pedir -u "$SMOKE_USUARIO:$SMOKE_CLAVE" "$api/api/tercerizados/me/" >/dev/null \
    || { log "Smoke: el GET autenticado falla."; exit 1; }
  log "Smoke: GET autenticado correcto."
else
  log "Smoke: sin SMOKE_USUARIO, se omite el GET autenticado."
fi
