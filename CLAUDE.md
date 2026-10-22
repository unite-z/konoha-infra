# konoha-infra

Infraestructura y despliegue del sistema de gestión de áreas verdes del campus PUCP (DP2). También es el hogar de los estándares transversales y del registro de decisiones (ADR) de los tres repos.

Repos hermanos: `konoha-backend` (Spring Boot) y `konoha-frontend` (React PWA).

## Mapa

| Ruta | Qué hay |
|---|---|
| `terraform/` | EC2, security group, IP elástica, EBS cifrado y bucket S3. Se aplica en local |
| `terraform/cloud-init.yml` | Preparación del host: Docker, swap, rotación de logs, usuario `deploy` y cron |
| `compose/edge/` | Caddy de borde: HTTPS y enrutado por host |
| `compose/uat/`, `compose/prod/` | Stack de cada entorno: `*-web`, `*-api` y `*-db` |
| `scripts/` | `deploy.sh`, `volver-atras.sh`, `backup.sh`, `restaurar-backup.sh`, `verificar-digest.sh`, `smoke-test.sh` y `levantar-edge.sh`. En el host viven en `/opt/konoha/infra/scripts/` |
| `docs/estandares/` | Normas comunes: nombres, git y PR, seguridad |
| `docs/adr/` | Registro único de decisiones |
| `docs/runbooks/` | Procedimientos: arrancar el lab, desplegar, volver atrás, restaurar y transferir |
| `.github/workflows/` | `ci.yml` (higiene, Terraform, Compose y shellcheck), `promover-prod.yml` y `sincronizar-host.yml` |

## Comandos

```sh
cd terraform
terraform fmt -check -recursive
terraform init
terraform validate
tflint --init && tflint
# plan y apply solo con aprobación: gastan crédito del lab (docs/runbooks/arrancar-lab.md)
```

Validar Compose en local:

```sh
REGISTRO_IMAGENES=ghcr.io/ejemplo API_SHA=0 WEB_SHA=0 KONOHA_DIR=/tmp/konoha \
  docker compose -f compose/uat/docker-compose.yml config --quiet
```

## Reglas no negociables

- **Nada de `aws_iam_*`** en Terraform: en el Learner Lab no se pueden crear roles. Se usa `LabInstanceProfile`.
- **Ninguna credencial de AWS en GitHub Actions.** El despliegue va por SSH con el usuario `deploy`.
- **Nunca se versiona el `.tfstate`**, ni `.tfvars` con valores reales, ni los `.env` de los stacks.
- Prod solo recibe imágenes ya desplegadas en UAT, identificadas por SHA. Nunca `:latest`.
- Antes de cualquier despliegue a prod: `pg_dump` a S3. Sin backup no hay despliegue.
- Las migraciones tienen que ser compatibles con la versión anterior de la api (expand/contract), porque la vuelta atrás solo cambia la imagen.
- UAT y prod comparten la EC2: no subas los límites de memoria de un entorno sin revisar la suma total (ADR 0003).
- Nombres en kebab-case, salvo las excepciones de `docs/estandares/nombres.md`. Los identificadores de Terraform van en snake_case.
- Todo en español de España: docs, commits y mensajes.

## Flujo de trabajo

Rama `<feat|fix|chore>/<ID>-<descripcion>`, commit `tipo(ID): descripción`, PR con squash. Detalle en `docs/estandares/git-y-prs.md`.
