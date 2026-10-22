# Una sola EC2 con Docker Compose para UAT y prod (ADR 0003).

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_vpc" "por_defecto" {
  default = true
}

resource "aws_security_group" "app" {
  name        = "konoha-app"
  description = "HTTP, HTTPS y SSH de la EC2 de konoha"
  vpc_id      = data.aws_vpc.por_defecto.id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP (redirige a HTTPS y valida certificados)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each          = toset(var.cidr_ssh)
  security_group_id = aws_security_group.app.id
  description       = "SSH solo con clave"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "todo" {
  security_group_id = aws_security_group.app.id
  description       = "Salida a internet (GHCR, S3, Gemini, Lets Encrypt)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = var.tipo_instancia
  key_name               = var.nombre_par_claves
  vpc_security_group_ids = [aws_security_group.app.id]

  # En el Learner Lab no se pueden crear roles: se usa el perfil que ya existe.
  iam_instance_profile = "LabInstanceProfile"

  user_data = templatefile("${path.module}/cloud-init.yml", {
    clave_publica_deploy = var.clave_publica_deploy
    nombre_bucket        = var.nombre_bucket
    region               = var.region
  })

  root_block_device {
    volume_type = "gp3"
    volume_size = var.tamano_disco_gb
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
    # Dos saltos: los contenedores también leen las credenciales del perfil.
    http_put_response_hop_limit = 2
  }

  tags = {
    Name = "konoha-app"
  }

  lifecycle {
    # Un cambio de AMI o de cloud-init no debe recrear la máquina (y su disco con las bases de datos).
    ignore_changes = [ami, user_data]
  }
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "konoha-app"
  }
}
