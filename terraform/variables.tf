variable "region" {
  description = "Región de AWS. En el Learner Lab, us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "tipo_instancia" {
  description = "Tipo de la EC2 que aloja UAT y prod (ADR 0003)."
  type        = string
  default     = "t3.medium"
}

variable "tamano_disco_gb" {
  description = "Tamaño del disco raíz gp3 cifrado, en GB."
  type        = number
  default     = 30
}

variable "nombre_par_claves" {
  description = "Par de claves de EC2 para el acceso de administración. El Learner Lab trae vockey."
  type        = string
  default     = "vockey"
}

variable "clave_publica_deploy" {
  description = "Clave pública SSH del usuario deploy, que usan los workflows de GitHub Actions."
  type        = string
}

variable "cidr_ssh" {
  description = "Rangos con acceso SSH. GitHub Actions no tiene IP fija, así que el acceso se protege con clave y sin contraseña."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3 de archivos y backups. Tiene que ser único en todo AWS."
  type        = string
}

variable "origenes_cors" {
  description = "Orígenes que pueden subir archivos directamente al bucket (URL de UAT y prod)."
  type        = list(string)
  default     = []
}

variable "dias_versiones_antiguas" {
  description = "Días que se conservan las versiones antiguas de los objetos del bucket."
  type        = number
  default     = 30
}

variable "dias_backups" {
  description = "Días que se conservan los backups de base de datos en S3."
  type        = number
  default     = 30
}
