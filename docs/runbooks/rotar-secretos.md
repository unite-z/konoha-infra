# Rotar secretos

Cuándo:

- al final de cada entrega;
- cuando alguien deja el equipo;
- **de inmediato** si un secreto se ha filtrado (gitleaks, captura, mensaje).

| Secreto | Cómo rotarlo |
|---|---|
| `SSH_KEY_DEPLOY` | Genera un par nuevo (`ssh-keygen -t ed25519 -C deploy-konoha`). Añade la pública a `/home/deploy/.ssh/authorized_keys` y actualiza el secret en los tres repos. Comprueba un despliegue y borra la pública vieja |
| `GHCR_TOKEN_LECTURA` | Token nuevo con `read:packages`. Actualiza `/opt/konoha/host.env` y revoca el viejo en GitHub |
| `DB_PASSWORD` de un entorno | `ALTER USER konoha PASSWORD '...'` dentro de `<entorno>-db`. Actualiza `api.env` y `db.env` de ese entorno y redespliega con `deploy.sh` |
| `GEMINI_API_KEY` | Clave nueva en Google AI Studio. Actualiza `api.env`, redespliega y borra la vieja |
| `DEPLOY_WEBHOOK_URL` | Regenera el webhook en Discord y actualiza el secret en los tres repos |
| Clave de usuarios de prueba (`MOD05_DEMO_PASSWORD`, `SMOKE_CLAVE`) | Cambia la contraseña del usuario en la aplicación y actualiza `host.env` |

Después de rotar:

1. Lanza `deploy-uat.yml` y comprueba que pasa.
2. Anota la fecha de la rotación en el canal del equipo, sin el valor.
