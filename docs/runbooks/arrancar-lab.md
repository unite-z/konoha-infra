# Arrancar el Learner Lab

La EC2 solo corre mientras la sesión del lab está abierta. Al cerrarla, AWS para la instancia. La IP elástica y los discos se conservan, así que la URL no cambia.

## Datos del lab (comprobados el 2026-10-22)

- Región: `us-east-1`.
- `LabInstanceProfile` (con `LabRole`) existe. No se pueden crear roles IAM.
- Se permiten t3.small, t3.medium y t3.large con ese perfil, y la IP elástica.
- SES y la Pricing API están denegados: no hay correo y los precios se miran en la calculadora web.
- Par de claves de administración: `vockey` (se descarga como `labsuser.pem` en AWS Details).

## Cada día

1. AWS Academy, Learner Lab, **Start Lab**. Espera a que el indicador esté en verde.
2. La EC2 arranca sola. Los contenedores tienen `restart: unless-stopped` y se levantan con Docker, que tarda unos dos minutos más.
3. Comprueba:

   ```sh
   curl -fsS https://uat.<ip-con-guiones>.sslip.io/api/health
   curl -fsS https://app.<ip-con-guiones>.sslip.io/api/health
   ```

4. La sesión dura unas 4 horas. Pulsar **Start Lab** otra vez reinicia el contador sin parar nada.
5. Los backups de `@reboot` corren a los 10 minutos del arranque.

## Antes de una sustentación o de la reunión con la sección

- Arranca el lab al menos 30 minutos antes y comprueba los dos health.
- Revisa que prod corre la versión acordada (`desplegar.md`, «Qué corre en cada entorno»).
- No fusiones en `main` el viernes antes de la reunión de las 15:30.

## Credenciales para Terraform (solo quien administra la infra)

AWS Details, AWS CLI: copia el bloque en `~/.aws/credentials` con el perfil `dp2-lab`. Caducan al cerrar la sesión.

```sh
export AWS_PROFILE=dp2-lab
aws sts get-caller-identity
```

## Crear la infraestructura por primera vez

Crear recursos gasta crédito del lab: **solo con la aprobación de quien coordina el equipo.**

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars   # completa la clave pública de deploy y el nombre del bucket
../scripts/crear-bucket.sh <nombre_bucket>     # el bucket se crea fuera de Terraform (ver terraform/s3.tf)
terraform init
terraform plan -out plan.tfplan
terraform apply plan.tfplan
terraform output
```

Después:

1. Con la IP elástica, rellena `origenes_cors` en `terraform.tfvars` y vuelve a aplicar.
2. Sigue `desplegar.md`, «Primera vez».

El bucket no está en el estado de Terraform por una restricción del lab: `terraform destroy` no lo borra, y hay que vaciarlo y borrarlo a mano si alguna vez se quiere eliminar.

El estado de Terraform es local hasta que se active el backend S3 (comentado en `versiones.tf`). No lo borres ni lo subas al repo. Guárdalo también en el almacenamiento del equipo tras cada `apply`.

## Si se agota el crédito

La cuenta se desactiva y se pierde todo, incluidos los backups de S3. Por eso, una vez por semana, descarga el último backup de prod y guárdalo cifrado fuera de la cuenta:

```sh
aws s3 ls s3://<bucket>/backups/prod/ | tail -1
aws s3 cp s3://<bucket>/backups/prod/<fichero>.dump .
```
