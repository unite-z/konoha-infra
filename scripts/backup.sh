#!/usr/bin/env bash
# pg_dump de un entorno a S3: s3://<bucket>/backups/<entorno>/<fecha>.dump
# Uso: backup.sh <uat|prod>
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
validar_entorno "$entorno"
cargar_host

contenedor="$(compose "$entorno" ps -q "$entorno-db" 2>/dev/null || true)"
[[ -n "$contenedor" ]] || { log "Backup: $entorno-db no está corriendo; nada que copiar."; exit 0; }

clave="backups/$entorno/$(date '+%Y%m%dT%H%M%S').dump"
log "Backup de $entorno a s3://${BUCKET:?Falta BUCKET}/$clave"

# El cliente de AWS corre en un contenedor y toma las credenciales del perfil de la instancia.
docker exec "$contenedor" pg_dump -U konoha -d konoha -Fc \
  | docker run --rm -i -e AWS_REGION="${AWS_REGION:-us-east-1}" amazon/aws-cli:2.22.35 \
      s3 cp - "s3://$BUCKET/$clave" --only-show-errors
log "Backup de $entorno terminado."
