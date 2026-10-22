# Seguridad y secretos

## Reglas

1. **Ningún secreto en el repositorio**: ni en código, ni en `.env.example`, ni en tests, ni en el historial. `.env.example` lleva las claves con el valor vacío.
2. **gitleaks** corre en el hook `pre-commit` (si está instalado) y en CI en cada PR. Un hallazgo bloquea el PR.
3. **Si se filtra un secreto**: primero se rota (se genera uno nuevo y se invalida el viejo), después se limpia. Borrar el commit no basta: hay que darlo por comprometido.
4. Cada entorno tiene **sus propios secretos**. UAT nunca usa una clave de prod, ni siquiera de forma temporal.
5. Todo lo que empieza por `VITE_` acaba en el navegador: **no es secreto**. Las claves de servicios de pago (Gemini) solo viven en el backend.

## Dónde vive cada secreto

| Dónde | Cómo |
|---|---|
| Tu máquina | `.env` local, ignorado por git |
| CI | GitHub, Settings, Secrets and variables, Actions |
| UAT y prod | `.env` de cada stack en la EC2, con permisos `600`, escrito por el workflow de despliegue por SSH |

| Secreto | Dónde | Notas |
|---|---|---|
| `MOD05_DB_PASSWORD` y `POSTGRES_PASSWORD` | `api.env` y `db.env` de cada entorno en el host | Distinta en UAT y prod |
| `GEMINI_API_KEY` | `.env` del backend | Una clave por entorno, con cuota propia en UAT |
| `GHCR_TOKEN_LECTURA` | `/opt/konoha/host.env` | Token de GitHub de solo lectura de paquetes, para el `docker pull` de la EC2 |
| `SSH_KEY_DEPLOY` | Secret de Actions | Clave del usuario `deploy` de la EC2, sin sudo. Está en el grupo `docker`, que equivale a root en el host: trátala como una credencial de administración |
| `SSH_KNOWN_HOSTS` | Secret de Actions | Huella del host, para que SSH no acepte un servidor suplantado |
| `DEPLOY_WEBHOOK_URL` | Secret de Actions | Webhook de Discord para avisar de fallos. Si falta, el aviso se salta |

Los secretos se rotan al final de cada entrega y siempre que alguien deje el equipo: `docs/runbooks/rotar-secretos.md`.

## Autenticación y permisos

- El backend decide siempre: la interfaz solo oculta lo que el rol no puede hacer.
- Contraseñas con BCrypt. Nunca se registran en logs ni se devuelven en respuestas.
- Fuera de `localhost`, todo va por HTTPS (Caddy de borde).
- Cada endpoint nuevo entra en la matriz de permisos por rol (ver `pruebas.md` del backend).

## Datos personales y logs

- Nada de contraseñas, tokens, cabeceras `Authorization` ni datos personales en logs.
- Los volcados de prod no salen de la cuenta de AWS salvo la copia periódica de seguridad, cifrada.
- No se restaura un volcado de prod en UAT sin reescribir las claves de S3 (ver `almacenamiento.md` del backend).

## Dependencias

- Dependabot abre PR semanales y agrupados para Maven, npm, Docker y GitHub Actions.
- Las acciones de terceros se fijan por SHA completo, no por etiqueta.

## Avisar de una vulnerabilidad

Ver `SECURITY.md` de cada repo.
