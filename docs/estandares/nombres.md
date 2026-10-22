# Nombres

Regla general: **minúsculas, palabras separadas por guiones, sin espacios ni tildes** (kebab-case).
Ejemplo: `asi-en-minusculas`.

## Dónde se aplica

| Qué | Ejemplo |
|---|---|
| Repositorios | `konoha-backend` |
| Carpetas | `docs/estandares`, `compose/uat` |
| Ficheros `.md` | `docs/adr/0001-backend-spring-boot.md` |
| Workflows | `.github/workflows/deploy-uat.yml` |
| Plantillas y scripts | `scripts/verificar-digest.sh` |
| Ficheros de Terraform y Compose | `terraform/red.tf`, `compose/prod/docker-compose.yml` |
| Ramas | `feat/AV-12-registro-de-poda` |
| Jobs y entornos | `ci-ok`, `uat`, `prod` |
| Servicios de Compose e imágenes | `prod-api`, `ghcr.io/<owner>/konoha-api` |
| Etiquetas de issues | `tipo-bug`, `necesita-decision` |
| Claves de configuración propias | `areas-verdes.almacenamiento.prefijo` |
| Rutas de la API | `/api/v1/tercerizados/atenciones/{id}/orden-compra/` |

El ID del ticket conserva el formato del tablero (mayúsculas): `feat/AV-12-...`.

## Excepciones

Las impone el lenguaje o la herramienta. Fuera de esta lista no hay más.

| Caso | Formato | Ejemplo |
|---|---|---|
| Clases Java | PascalCase | `AtencionService` |
| Paquetes Java | minúsculas sin guiones | `pe.edu.pucp.areasverdes.mod05` |
| Métodos y campos Java | camelCase | `registrarInicio` |
| Constantes Java | MAYÚSCULAS con guion bajo | `TAMANO_PAGINA` |
| Componentes React y su CSS | PascalCase | `BarraAvance.tsx`, `BarraAvance.module.css` |
| Carpeta de un componente con varios ficheros | PascalCase | `layouts/LayoutOficina/` |
| Ficheros TS que no son componentes | camelCase, como ya hace el repo | `clienteTercerizados.ts`, `useConsulta.ts` |
| Ficheros de entrada fijados por la herramienta | los de la herramienta | `main.tsx`, `App.tsx`, `vite.config.ts` |
| Migraciones Flyway | `V<n>__<modulo>_<descripcion>.sql` | `V2__mod05_agrega_motivo_rechazo.sql` |
| Tablas y columnas SQL | snake_case con prefijo de módulo | `mod05_registro_auditoria` |
| Identificadores de Terraform | snake_case (convención de HCL y tflint) | `aws_instance.app`, `variable "tipo_instancia"` |
| Claves JSON de la API | camelCase (ver `api.md` del backend) | `fechaInicio` |
| Variables de entorno | SCREAMING_SNAKE_CASE | `S3_PREFIX`, `GEMINI_API_KEY` |
| Variables y secrets de GitHub Actions | SCREAMING_SNAKE_CASE | `DESPLIEGUE_ACTIVO`, `SSH_HOST_UAT` |
| Ficheros con nombre fijado | el fijado | `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`, `Dockerfile`, `.env.example`, `docker-compose.yml` |
| Rutas fijadas por GitHub | las de GitHub | `.github/ISSUE_TEMPLATE/`, `.github/pull_request_template.md` |

## Cómo se comprueba

El job `higiene` de `ci.yml` revisa los ficheros **añadidos o renombrados** en el PR y falla si un nombre no cumple la regla ni ninguna excepción. Los ficheros que ya existían no se tocan solo por el nombre: se renombran en un PR propio si hace falta.
