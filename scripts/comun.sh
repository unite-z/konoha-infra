#!/usr/bin/env bash
# Funciones compartidas por los scripts de despliegue. Se carga con: source "$(dirname "$0")/comun.sh"
# shellcheck disable=SC2034  # las variables las usan los scripts que cargan este fichero

set -euo pipefail

KONOHA_DIR="${KONOHA_DIR:-/opt/konoha}"
INFRA_DIR="${INFRA_DIR:-$KONOHA_DIR/infra}"
export KONOHA_DIR

log() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2; }
error() { log "ERROR: $*"; exit 1; }

# sha256sum en Linux; shasum en macOS (pruebas locales).
if command -v sha256sum >/dev/null 2>&1; then SHA256=(sha256sum); else SHA256=(shasum -a 256); fi

validar_entorno() {
  case "${1:-}" in
    uat | prod) ;;
    *) error "Entorno no válido: '${1:-}'. Usa uat o prod." ;;
  esac
}

# Carga host.env (registro de imágenes, token de GHCR, bucket, dominios).
cargar_host() {
  if [[ -f "$KONOHA_DIR/host.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "$KONOHA_DIR/host.env"
    set +a
  fi
}

compose() {
  local entorno="$1"
  shift
  docker compose \
    --project-name "konoha-$entorno" \
    --file "$INFRA_DIR/compose/$entorno/docker-compose.yml" \
    --env-file "$KONOHA_DIR/$entorno/version.env" \
    "$@"
}

# Lee una clave de version.env sin ejecutar el fichero.
leer_version() {
  local fichero="$1" clave="$2"
  grep -E "^$clave=" "$fichero" | tail -n 1 | cut -d= -f2-
}

avisar_fallo() {
  local mensaje="$1"
  if [[ -n "${DEPLOY_WEBHOOK_URL:-}" ]]; then
    curl -fsS -m 10 -H 'Content-Type: application/json' \
      -d "$(jq -n --arg c "$mensaje" '{content: $c}')" "$DEPLOY_WEBHOOK_URL" >/dev/null || true
  fi
}

# Descarga un respaldo (directorio backups/<entorno>/<fecha>) de S3 a un directorio local.
# Con BACKUP_DESTINO_LOCAL lo copia de ahí (pruebas sin S3).
descargar_backup() {
  local clave="$1" destino="$2"
  mkdir -p "$destino"
  if [[ -n "${BACKUP_DESTINO_LOCAL:-}" ]]; then
    [[ -d "$BACKUP_DESTINO_LOCAL/$clave" ]] || error "No existe el respaldo $BACKUP_DESTINO_LOCAL/$clave."
    cp "$BACKUP_DESTINO_LOCAL/$clave"/* "$destino/"
  else
    docker run --rm -e AWS_REGION="${AWS_REGION:-us-east-1}" -v "$destino":/b amazon/aws-cli:2.22.35 \
      s3 cp "s3://${BUCKET:?Falta BUCKET}/$clave/" /b --recursive --only-show-errors \
      || error "No se ha podido descargar $clave."
  fi
}
