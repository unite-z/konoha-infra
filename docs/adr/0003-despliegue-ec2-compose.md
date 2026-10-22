# 0003. Despliegue en una EC2 con Docker Compose

- Estado: aceptado
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

- AWS Academy Learner Lab:
  - credenciales temporales;
  - no se pueden crear roles IAM (se usa `LabRole` / `LabInstanceProfile`);
  - las EC2 se paran al cerrar la sesión;
  - el crédito pertenece a un solo alumno.
- Unos 35 usuarios y 1.084 árboles.
- El curso exige nube, PWA, API, pruebas automatizadas, CI/CD, auditoría, IA con propósito y despliegue reproducible.

## Decisión

- **Una EC2 t3.medium** (4 GB, swap de 2 GB) en `us-east-1`, con IP elástica y EBS gp3 cifrado.
- Docker Compose con estos servicios:
  - `edge`: Caddy. Solo termina HTTPS (dominios sslip.io) y enruta por host.
  - `uat-web`, `uat-api`, `uat-db`.
  - `prod-web`, `prod-api`, `prod-db`.
- `*-web` sirve el build estático de la PWA (`sw.js` sin caché). `*-api` es el backend. `*-db` es PostGIS con volumen propio.
- Límites de memoria:

  | Entorno | api | db |
  |---|---|---|
  | prod | 1 GB | 640 MB |
  | uat | 640 MB | 384 MB |

  La JVM va con `-XX:MaxRAMPercentage=65`. Se mide con `docker stats` la primera semana.
- Healthcheck de las api en `/api/health` con `start_period` de 120 s.
- S3: un bucket versionado con prefijos `uat/` y `prod/`, acceso por `LabInstanceProfile` (sin claves). EBS cifrado. CORS para la subida directa desde la PWA.
- Las alertas diarias van con `@Scheduled` en la api (a las 06:00 y al arrancar, con la marca de la última ejecución). El cron del host solo hace `pg_dump` a S3 y limpieza.
- Flujo de despliegue:
  - PR: solo CI.
  - Fusión en `main`: despliegue a UAT.
  - `promover-prod.yml` (manual): lleva a prod la misma imagen probada en UAT, con `pg_dump` previo, verificación de digest, smoke test y vuelta atrás.
- Terraform aplicado en local. CI no tiene credenciales de AWS: despliega por SSH.

## Comprobado en el lab (2026-10-22)

Verificado con `--dry-run` y lecturas, sin crear recursos:

| Comprobación | Resultado |
|---|---|
| `LabInstanceProfile` | Existe y lleva `LabRole` |
| `run-instances` t3.small, t3.medium y t3.large con `LabInstanceProfile` en `us-east-1` | Permitido |
| IP elástica (`allocate-address`) en `us-east-1` y `us-west-2` | Permitido |
| AMI | Ubuntu 24.04, que Terraform resuelve con el parámetro público de SSM, sin fijar el ID |
| SES | `AccessDenied`. Las alertas van solo dentro de la aplicación |
| Pricing API | `AccessDenied`. Los precios se confirman en la calculadora web de AWS |

Queda por confirmar el presupuesto de crédito del lab.

## Alternativas descartadas

- ECS, RDS o ALB: caros para el crédito del lab y chocan con las restricciones de IAM.
- Lightsail: precio fijo y sin instance profile, así que S3 necesitaría claves, que en el lab caducan.
- Dos EC2 (una por entorno): más aislamiento, pero el doble de coste. Es el plan B si UAT molesta a prod, con el mismo Terraform.

## Consecuencias

- Unos 14 USD al mes con 6 horas diarias de lab.
- La aplicación solo está disponible mientras alguien tiene la sesión del lab abierta. Para las sustentaciones, se arranca con margen.
- UAT y prod comparten el `LabInstanceProfile`: los prefijos de S3 no aíslan. Se mitiga con el guard de prefijo en el código y con el versionado del bucket.
- Si el alumno dueño de la cuenta agota su crédito, se pierde todo. Hay que sacar periódicamente una copia de la base fuera de la cuenta.
