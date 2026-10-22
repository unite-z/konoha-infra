# Desplegar

## Flujo normal

| Paso | Dónde | Qué pasa |
|---|---|---|
| Fusión en `main` de `konoha-backend` | `deploy-uat.yml` | Imagen `konoha-api:<sha>` en GHCR y `deploy.sh uat api <sha>` |
| Fusión en `main` de `konoha-frontend` | `deploy-uat.yml` | Imagen `konoha-web:<sha>` en GHCR y `deploy.sh uat web <sha>` |
| Fusión en `main` de `konoha-infra` que toca `compose/` o `scripts/` | `sincronizar-host.yml` | Copia los ficheros a la EC2 y actualiza el borde |
| Promoción manual | `promover-prod.yml` en `konoha-infra` | `deploy.sh prod ambos <api> <web>` con la versión que corre en UAT |

`deploy.sh`:

1. Descarga las imágenes. En prod, además, hace `pg_dump` a S3.
2. Levanta el entorno y espera a que los contenedores estén sanos.
3. Comprueba que corren el digest esperado.
4. Pasa el smoke test.

Si algo falla, vuelve sola a la versión anterior y el workflow avisa en Discord.

Si el lab está apagado, el workflow falla con «La EC2 no responde por SSH». Arranca el lab y relánzalo desde la pestaña Actions (**Re-run jobs**).

## Promover a prod

1. Comprueba UAT con la sección o con el equipo.
2. `konoha-infra`, Actions, **promover-prod**, Run workflow. Deja los SHA vacíos para llevar exactamente lo que corre en UAT.
3. El workflow rechaza cualquier combinación de api y web que no haya pasado con éxito por UAT.

## Qué corre en cada entorno

```sh
# prod: último deployment correcto en konoha-infra, con api_sha y web_sha en el payload
gh api "repos/<owner>/konoha-infra/deployments?environment=prod&per_page=5" \
  --jq '.[] | {fecha: .created_at, api: .payload.api_sha, web: .payload.web_sha}'

# uat: pestaña Environments de konoha-backend (api) y konoha-frontend (web)
gh api "repos/<owner>/konoha-backend/deployments?environment=uat&per_page=1" --jq '.[0].sha'

# en el host, la fuente que usa deploy.sh
ssh deploy@<ip> cat /opt/konoha/prod/version.env /opt/konoha/uat/version.env
```

## Primera vez

Con la EC2 creada (`arrancar-lab.md`):

1. **Clave de deploy.** El par de claves cuya pública va en `terraform.tfvars`. La privada se guarda como secret `SSH_KEY_DEPLOY` en los tres repos.
2. **known_hosts.** Desde tu máquina, `ssh-keyscan -t ed25519 <ip>`. Guarda la salida como secret `SSH_KNOWN_HOSTS` en los tres repos.
3. **Variables de Actions en los tres repos**:

   | Variable | Valor |
   |---|---|
   | `SSH_HOST` | IP elástica |
   | `URL_UAT` | `https://uat.<ip-con-guiones>.sslip.io` |
   | `URL_PROD` | `https://app.<ip-con-guiones>.sslip.io` |
   | `DESPLIEGUE_ACTIVO` | `true` (mientras sea `false` o no exista, los deploys se saltan) |
   | `PREFIJO_TICKET` | `AV` |

4. **Token de GHCR.** Crea un token clásico con solo `read:packages`, de una cuenta con acceso a los paquetes. En la EC2:

   ```sh
   ssh -i labsuser.pem ubuntu@<ip>
   sudo -u deploy nano /opt/konoha/host.env
   ```

   Añade estas claves, una por línea con el formato `CLAVE=valor` (el token y la clave, nunca en el repo):

   | Clave | Valor |
   |---|---|
   | `REGISTRO_IMAGENES` | `ghcr.io/<owner-en-minusculas>` |
   | `GHCR_USUARIO` | Usuario de GitHub dueño del token |
   | `GHCR_TOKEN_LECTURA` | El token con `read:packages` |
   | `SMOKE_USUARIO` | Usuario de prueba, por ejemplo `mod05_ingeniero` |
   | `SMOKE_CLAVE` | Su clave en ese entorno |

5. **Ficheros de entorno.** Con los ejemplos de `compose/<entorno>/*.env.example` y `compose/edge/edge.env.example`, crea en la EC2:
   - `/opt/konoha/uat/api.env` y `db.env`;
   - `/opt/konoha/prod/api.env` y `db.env`;
   - `/opt/konoha/edge/edge.env`.

   Todos con `chmod 600` y con contraseñas distintas en UAT y en prod.
6. **Ficheros de infra en el host.** Ejecuta `sincronizar-host.yml` a mano. Copia `compose/` y `scripts/` y levanta el borde.
7. **Primer despliegue de cada entorno.** Hace falta una imagen de api y otra de web: ejecuta `deploy-uat.yml` a mano en backend y frontend. Como el primer despliegue de un entorno tiene que llevar los dos componentes, la primera ejecución falla con un mensaje claro. Entonces, en la EC2:

   ```sh
   sudo -u deploy /opt/konoha/infra/scripts/deploy.sh uat ambos <sha-api> <sha-web>
   ```

   Después, `promover-prod.yml` para prod.
8. **Precarga.** Para cargar los usuarios de prueba, añade `SPRING_PROFILES_ACTIVE=dev` y `MOD05_SEED=true` al `api.env` de UAT. Redespliega y **quítalos** después.

## Imágenes antiguas

`limpiar-imagenes.yml` (backend y frontend) conserva las 10 versiones más recientes de cada imagen cada lunes. Si una ejecución falla por permisos: en el paquete de GHCR, Package settings, Manage Actions access, da al repo el rol **Admin**.
