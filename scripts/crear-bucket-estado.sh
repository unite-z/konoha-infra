#!/usr/bin/env bash
# Crea el bucket del estado de Terraform si no existe: privado, cifrado y con versionado
# para poder recuperar un estado anterior. Se ejecuta una vez por cuenta, antes de
# terraform init (docs/runbooks/arrancar-lab.md).
#
# Uso: AWS_PROFILE=<perfil> scripts/crear-bucket-estado.sh <nombre-bucket> [region]
set -euo pipefail

bucket="${1:?Indica el nombre del bucket de estado (konoha-tfstate-<sufijo>)}"
region="${2:-us-east-1}"

if ! aws s3api head-bucket --bucket "$bucket" >/dev/null 2>&1; then
  if [ "$region" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$bucket" --region "$region" >/dev/null
  else
    aws s3api create-bucket --bucket "$bucket" --region "$region" \
      --create-bucket-configuration "LocationConstraint=$region" >/dev/null
  fi
  echo "Bucket $bucket creado en $region."
fi

aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket "$bucket" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled
echo "Bucket $bucket listo. Ahora: terraform init -backend-config=\"bucket=$bucket\"."
