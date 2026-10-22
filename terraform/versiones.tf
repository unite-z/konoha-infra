terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Estado remoto en S3, en la misma cuenta del lab. Se activa tras crear el bucket de estado
  # a mano (ver docs/runbooks/arrancar-lab.md). Mientras tanto, el estado es local y no se versiona.
  # backend "s3" {
  #   bucket       = "konoha-tfstate-<sufijo>"
  #   key          = "konoha/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  # }
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
