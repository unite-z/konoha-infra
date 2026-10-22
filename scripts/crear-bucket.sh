#!/usr/bin/env bash
# Crea el bucket de archivos y backups si no existe. Se ejecuta una vez por cuenta, antes
# de terraform apply (docs/runbooks/arrancar-lab.md). Terraform no puede gestionar el
# bucket en sí por una restricción del Learner Lab (ver terraform/s3.tf).
#
# Uso: AWS_PROFILE=<perfil> scripts/crear-bucket.sh <nombre-bucket> [region]
set -euo pipefail

bucket="${1:?Indica el nombre del bucket (el de nombre_bucket en terraform.tfvars)}"
region="${2:-us-east-1}"

if aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  echo "El bucket $bucket ya existe."
  exit 0
fi

if [ "$region" = "us-east-1" ]; then
  aws s3api create-bucket --bucket "$bucket" --region "$region" >/dev/null
else
  aws s3api create-bucket --bucket "$bucket" --region "$region" \
    --create-bucket-configuration "LocationConstraint=$region" >/dev/null
fi
echo "Bucket $bucket creado en $region. Ahora: terraform apply."
