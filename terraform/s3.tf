# Bucket de archivos (prefijos uat/ y prod/) y backups (backups/uat/ y backups/prod/).
#
# El bucket se crea fuera de Terraform con scripts/crear-bucket.sh: la política del
# Learner Lab deniega s3:GetBucketObjectLockConfiguration, que el proveedor de AWS lee
# siempre que gestiona un aws_s3_bucket. Terraform sí gestiona toda su configuración.
# Al no estar en el estado, un terraform destroy no puede borrarlo por accidente.

resource "aws_s3_bucket_public_access_block" "archivos" {
  bucket                  = var.nombre_bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "archivos" {
  bucket = var.nombre_bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "archivos" {
  bucket = var.nombre_bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "archivos" {
  bucket = var.nombre_bucket

  rule {
    id     = "versiones-antiguas"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = var.dias_versiones_antiguas
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 2
    }
  }

  rule {
    id     = "backups"
    status = "Enabled"
    filter {
      prefix = "backups/"
    }
    expiration {
      days = var.dias_backups
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "archivos" {
  count  = length(var.origenes_cors) > 0 ? 1 : 0
  bucket = var.nombre_bucket

  cors_rule {
    allowed_methods = ["PUT", "GET"]
    allowed_origins = var.origenes_cors
    allowed_headers = ["Content-Type", "Content-MD5", "x-amz-*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
