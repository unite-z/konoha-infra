output "ip_publica" {
  description = "IP elástica de la EC2."
  value       = aws_eip.app.public_ip
}

output "dominio_uat" {
  description = "Dominio de UAT en sslip.io."
  value       = "uat.${replace(aws_eip.app.public_ip, ".", "-")}.sslip.io"
}

output "dominio_prod" {
  description = "Dominio de prod en sslip.io."
  value       = "app.${replace(aws_eip.app.public_ip, ".", "-")}.sslip.io"
}

output "bucket" {
  description = "Bucket de archivos y backups."
  value       = aws_s3_bucket.archivos.bucket
}

output "ssh_deploy" {
  description = "Comando SSH del usuario deploy."
  value       = "ssh deploy@${aws_eip.app.public_ip}"
}
