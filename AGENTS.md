# konoha-infra

Infraestructura y despliegue del sistema de gestión de áreas verdes del campus PUCP (DP2). También aloja los estándares transversales y el registro de decisiones (ADR) de los tres repos.

Este fichero es la guía para personas y agentes. Repos hermanos: `konoha-backend` (Spring Boot) y `konoha-frontend` (React PWA).

## Estado

- Sprint 0 (en curso): Terraform, Compose, scripts, workflows y runbooks listos y validados en local.
- La EC2 no está creada: `terraform apply` requiere la aprobación de quien coordina, porque gasta crédito del lab.
- Los deploys y `sincronizar-host.yml` se saltan hasta que la variable `DESPLIEGUE_ACTIVO` valga `true`.

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
| `docs/runbooks/` | Procedimientos: arrancar el lab, desplegar, volver atrás, restaurar, rotar y transferir |
| `.github/workflows/` | `ci.yml` (higiene, Terraform, Compose y shellcheck), `promover-prod.yml` y `sincronizar-host.yml` |

## Comandos

```sh
cd terraform
terraform fmt -check -recursive
terraform init -backend=false && terraform validate
tflint --init && tflint
# plan y apply solo con aprobación: gastan crédito del lab (docs/runbooks/arrancar-lab.md)
```

## Gates: lo que tiene que pasar antes de pushear

Es lo mismo que exige `ci-ok`:

```sh
(cd terraform && terraform fmt -check -recursive && terraform init -backend=false -input=false && terraform validate && tflint)
shellcheck -x scripts/*.sh .github/scripts/*.sh .githooks/*
mkdir -p /tmp/konoha/uat /tmp/konoha/prod
for e in uat prod; do cp compose/$e/api.env.example /tmp/konoha/$e/api.env; cp compose/$e/db.env.example /tmp/konoha/$e/db.env; done
for e in uat prod; do REGISTRO_IMAGENES=ghcr.io/ejemplo API_SHA=0 WEB_SHA=0 KONOHA_DIR=/tmp/konoha docker compose -f compose/$e/docker-compose.yml config --quiet; done
```

En el PR, CI comprueba además el título, la rama, los nombres de fichero, los artefactos, los secretos (gitleaks) y el Caddyfile.

## Reglas no negociables

- **Nada de `aws_iam_*`** en Terraform: en el Learner Lab no se pueden crear roles. Se usa `LabInstanceProfile`.
- **Ninguna credencial de AWS en GitHub Actions.** El despliegue va por SSH con el usuario `deploy`.
- **Nunca se versiona el `.tfstate`**, ni `.tfvars` con valores reales, ni los `.env` de los stacks.
- **`plan` y `apply` contra la cuenta del lab, solo con aprobación** de quien coordina.
- Prod solo recibe imágenes ya desplegadas con éxito en UAT, identificadas por SHA. Nunca `:latest`.
- Antes de cualquier despliegue a prod: `pg_dump` a S3. Sin backup no hay despliegue.
- Las migraciones tienen que ser compatibles con la versión anterior de la api (expand/contract), porque la vuelta atrás solo cambia la imagen.
- UAT y prod comparten la EC2: no subas los límites de memoria de un entorno sin revisar la suma total (ADR 0003).
- Nada de cambios a mano en el host que no estén en este repo. Todo entra por PR y `sincronizar-host.yml`.
- Scripts compatibles con bash 5 en el host y con el bash 3.2 de macOS en los hooks.
- Nombres en kebab-case, salvo las excepciones de `docs/estandares/nombres.md`. Los identificadores de Terraform van en snake_case.
- Todo en español de España: docs, commits y mensajes.

## Decisiones cerradas (no se re-discuten)

Cambiarlas exige un ADR nuevo que sustituya al anterior.

| Decisión | Dónde |
|---|---|
| Backend en Spring Boot 3.5 con Java 21 | [ADR 0001](docs/adr/0001-backend-spring-boot.md) |
| Tres repos: backend, frontend e infra | [ADR 0002](docs/adr/0002-repos-backend-frontend-infra.md) |
| Una EC2 con Docker Compose; entornos UAT y prod, sin DEV en la nube | [ADR 0003](docs/adr/0003-despliegue-ec2-compose.md) |
| Alertas solo dentro de la aplicación (SES denegado en el lab) | [ADR 0003](docs/adr/0003-despliegue-ec2-compose.md) |
| Estado de los entornos en la API de Deployments de GitHub | [ADR 0002](docs/adr/0002-repos-backend-frontend-infra.md) |
| Flyway con expand/contract y propiedad de entidades por módulo | `konoha-backend`: `docs/estandares/base-datos.md` |
| Prefijo de tickets `AV` (provisional, en un solo sitio) | [git-y-prs.md](docs/estandares/git-y-prs.md) |

Pendientes de decisión: formato de errores (ADR 0004, propuesto), claves JSON (ADR 0005) y nombres de ficheros TS que no son componentes.

## Seguridad abierta: no empeorar

- SSH abierto a internet (puerto 22, solo con clave), porque GitHub Actions no tiene IP fija.
- El usuario `deploy` está en el grupo `docker`, que equivale a root en el host.
- UAT y prod comparten `LabInstanceProfile`: los prefijos de S3 no aíslan los entornos (ADR 0003).
- Los backups viven en la misma cuenta del lab. La copia fuera de la cuenta es manual (`arrancar-lab.md`).
- El estado de Terraform es local hasta activar el backend S3.

Ningún PR puede ampliar estas brechas. Cerrarlas va en tickets propios.

## Qué no entra al repo

- `.env`, `*.tfvars`, `*.tfstate`, `.terraform/`, credenciales, tokens y claves SSH.
- Volcados de base de datos y datos reales de la sección.
- PDF de entregables del curso y capturas con datos personales.
- Salidas de herramientas (`.bin/`) y binarios de más de 5 MB.

## Planes y artefactos de sesión

Los planes, notas y borradores de trabajo de personas y agentes van en `.notas/` (ignorada por git) o fuera del repo. Nunca se commitean. Lo que deba perdurar se pasa a uno de los documentos de abajo.

## Mapa de documentos

| Documento | Para qué |
|---|---|
| `AGENTS.md` | Esta guía: estado, gates, reglas y decisiones |
| `CLAUDE.md` | Solo importa `AGENTS.md` |
| `README.md` | Qué es el proyecto, arquitectura y flujo de despliegue |
| `CONTRIBUTING.md` | Ciclo de trabajo común a los tres repos |
| `SECURITY.md` | Cómo avisar de una vulnerabilidad |
| `docs/estandares/*.md` | Nombres, git y PR, seguridad y secretos |
| `docs/adr/*.md` | Decisiones de arquitectura |
| `docs/runbooks/*.md` | Arrancar el lab, desplegar, volver atrás, restaurar, rotar y transferir |
| `.github/rulesets/README.md` | Cómo aplicar las reglas de `main` |

**No se crean documentos nuevos** sin fusionar antes su contenido en uno existente o justificar en el PR por qué no cabe.

## Flujo de trabajo

Rama `<feat|fix|chore>/<ID>-<descripcion>`, commit `tipo(ID): descripción`, PR con squash. Detalle en `docs/estandares/git-y-prs.md`.
