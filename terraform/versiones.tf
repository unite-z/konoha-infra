terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Estado remoto en S3, en la misma cuenta del lab, con bloqueo por fichero (use_lockfile).
  # El bucket se crea con scripts/crear-bucket-estado.sh y se pasa al iniciar:
  #   terraform init -backend-config="bucket=konoha-tfstate-<sufijo>"
  backend "s3" {
    key          = "konoha/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      proyecto = "konoha"
      gestion  = "terraform"
    }
  }
}
