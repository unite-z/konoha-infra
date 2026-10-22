# Estándares

Normas comunes a los tres repos. Las específicas de cada uno viven en su propio `docs/estandares/`.

| Fichero | Trata de |
|---|---|
| [nombres.md](nombres.md) | Regla kebab-case y sus excepciones |
| [git-y-prs.md](git-y-prs.md) | Tickets, ramas, commits, PR, calendario y minutos de Actions |
| [seguridad-secretos.md](seguridad-secretos.md) | Dónde vive cada secreto, permisos, logs y dependencias |

En `konoha-backend/docs/estandares/`:

| Fichero | Trata de |
|---|---|
| `estilo-codigo-java.md` | Formato, paquetes, inyección y SQL |
| `api.md` | Rutas, errores, paginación, idempotencia y OpenAPI |
| `base-datos.md` | Flyway, expand/contract, datos iniciales y PostGIS |
| `pruebas.md` | Unitarias, integración con PostGIS y matriz de permisos |
| `almacenamiento.md` | S3, prefijo por entorno y URL prefirmadas |

En `konoha-frontend/docs/estandares/`:

| Fichero | Trata de |
|---|---|
| `estilo-codigo-ts-react.md` | Estructura, nombres, tipos, estilos y accesibilidad |
| `pruebas.md` | Vitest y qué se prueba |
| `pwa-offline.md` | Cola sin conexión, idempotencia y service worker |

Las decisiones de arquitectura están en [`../adr/`](../adr/README.md).
