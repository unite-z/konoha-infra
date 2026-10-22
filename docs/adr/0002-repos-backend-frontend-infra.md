# 0002. Tres repositorios: backend, frontend e infra

- Estado: aceptado
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

La organización del curso ya tiene creados `konoha-backend`, `konoha-frontend` y `konoha-infra`, vacíos. El equipo aún no tiene permisos de escritura en ella. El borrador de código vive en un único repo con `backend/` y `frontend/`.

## Decisión

- Tres repositorios con esos nombres, privados en una cuenta personal mientras tanto, y transferidos a la organización cuando haya acceso (ver `docs/runbooks/transferir-a-la-organizacion.md`).
- El borrador se separa por carpeta conservando el historial y la autoría (`git filter-repo`).
- `konoha-backend` y `konoha-frontend` publican su imagen por SHA en GHCR (`konoha-api` y `konoha-web`) y despliegan en UAT al fusionar en `main`.
- `konoha-infra` contiene Terraform, Compose, scripts, runbooks, los estándares transversales y este registro de ADR. También la promoción a prod (`promover-prod.yml`).
- Qué SHA corre en cada entorno queda en la **API de Deployments de GitHub**, sin commits:
  - UAT, en `konoha-backend` (api) y `konoha-frontend` (web), con `environment: uat` en su `deploy-uat.yml`;
  - prod, en `konoha-infra`, con un payload que incluye `api_sha`, `web_sha`, quién lo lanzó y cuándo.

  Registrarlo todo en `konoha-infra` exigiría un token con acceso entre repos, y el `GITHUB_TOKEN` de cada repo solo escribe en el suyo. La fuente operativa es `/opt/konoha/<entorno>/version.env` en el host.

## Alternativas descartadas

- Monorepo de aplicación más infra: un solo CI y cambios atómicos entre front y back, pero no encaja con los repos que ya existen en la organización.

## Consecuencias

- La transferencia a la organización es directa, repo por repo.
- Un cambio que toca front y back son dos PR. Se coordinan con el mismo ticket y se despliega primero el backend, que tiene que ser compatible con el front anterior.
- Los estándares transversales viven en `konoha-infra`. Backend y frontend solo tienen los suyos y enlazan al resto.
