# konoha-infra

Infraestructura del sistema de gestión de áreas verdes del campus PUCP (curso DP2), los estándares comunes del equipo y el registro de decisiones.

| Repo | Contenido |
|---|---|
| `konoha-backend` | API en Spring Boot 3.5 y Java 21 |
| `konoha-frontend` | PWA en React 19, Vite y TypeScript |
| `konoha-infra` | Este repo: Terraform, Compose, scripts, runbooks, estándares y ADR |

## Arquitectura en una línea

Una EC2 t3.medium en el AWS Academy Learner Lab con Docker Compose: un Caddy de borde y dos stacks, UAT y prod, con su web, su api y su PostGIS. Los archivos van en S3. Detalle en [ADR 0003](docs/adr/0003-despliegue-ec2-compose.md).

```
Navegador ─HTTPS─► edge (Caddy) ─┬─ uat.<ip>.sslip.io ─► uat-web / uat-api ─► uat-db
                                  └─ app.<ip>.sslip.io ─► prod-web / prod-api ─► prod-db
                                                 uat-api y prod-api ─► S3 (prefijos uat/ y prod/)
```

## Flujo de despliegue

| Evento | Qué pasa |
|---|---|
| PR en cualquier repo | Solo CI |
| Fusión en `main` de backend o frontend | Imagen por SHA en GHCR y despliegue en UAT |
| `promover-prod.yml` (manual, aquí) | La misma imagen de UAT pasa a prod, con backup previo, verificación y vuelta atrás |

## Por dónde empezar

- Normas del equipo: [docs/estandares/](docs/estandares/README.md).
- Decisiones: [docs/adr/](docs/adr/README.md).
- Procedimientos: [docs/runbooks/](docs/runbooks/).
- Cómo contribuir: [CONTRIBUTING.md](CONTRIBUTING.md).

## Estado de los repos

Por ahora son privados en una cuenta personal. Cuando el equipo tenga acceso a la organización del curso, se transfieren siguiendo [transferir-a-la-organizacion.md](docs/runbooks/transferir-a-la-organizacion.md).
