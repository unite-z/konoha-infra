#!/usr/bin/env bash
# Restaura un backup de S3 en un entorno. Destructivo: sustituye la base actual.
# Uso: restaurar-backup.sh <uat|prod> <clave-s3>
#   restaurar-backup.sh prod backups/prod/20261022T130000.dump
# Nunca restaures un backup de prod en uat sin reescribir las claves de S3 (almacenamiento.md del backend).
# shellcheck source=comun.sh
source "$(dirname "$0")/comun.sh"

entorno="${1:-}"
clave="${2:?Falta la clave del backup en S3}"
validar_entorno "$entorno"
cargar_host

if [[ "$clave" != backups/"$entorno"/* ]]; then
  error "La clave $clave no es de $entorno. Restaurar entre entornos exige reescribir las claves de S3: hazlo a mano siguiendo el runbook."
fi

read -r -p "Se va a sustituir la base de $entorno por $clave. Escribe '$entorno' para continuar: " confirmacion
[[ "$confirmacion" == "$entorno" ]] || error "Cancelado."

"$(dirname "$0")/backup.sh" "$entorno"
compose "$entorno" stop "$entorno-api"
contenedor="$(compose "$entorno" ps -q "$entorno-db")"
docker run --rm -e AWS_REGION="${AWS_REGION:-us-east-1}" amazon/aws-cli:2.22.35 s3 cp "s3://$BUCKET/$clave" - --only-show-errors \
  | docker exec -i "$contenedor" pg_restore -U konoha -d konoha --clean --if-exists --no-owner
compose "$entorno" start "$entorno-api"
compose "$entorno" up -d --wait --wait-timeout 300
"$(dirname "$0")/smoke-test.sh" "$entorno"
log "Restauración de $entorno terminada."
