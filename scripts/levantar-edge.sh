#!/usr/bin/env bash
# Levanta o actualiza el Caddy de borde. Uso: levantar-edge.sh
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

docker network inspect konoha-edge >/dev/null 2>&1 || docker network create konoha-edge >/dev/null
docker compose \
  --project-name konoha-edge \
  --file "$INFRA_DIR/compose/edge/docker-compose.yml" \
  --env-file "$KONOHA_DIR/edge/edge.env" \
  up -d --remove-orphans
log "Borde levantado."
