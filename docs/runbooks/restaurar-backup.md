# Restaurar un backup

Un respaldo es la **base y los adjuntos** (fotos y documentos del volumen `archivos`) del mismo instante. Restaurar solo la base dejaría filas que apuntan a ficheros que no existen.

## Qué hay en S3

`s3://<bucket>/backups/<entorno>/<fecha>/`, con `<entorno>` = `uat` o `prod` (nunca se mezclan):

| Fichero | Contenido |
|---|---|
| `db.dump` | `pg_dump -Fc` de la base |
| `adjuntos.tar.gz` | contenido del volumen `archivos` (`/app/private-media`) |
| `SHA256SUMS` | checksums de los dos anteriores |
| `manifiesto.env` | entorno, fecha, nº de adjuntos y `estado=completo`. Se sube el último |

Se generan antes de cada despliegue a prod (`deploy.sh` aborta si falla), cada día a las 13:00 y 10 minutos después de arrancar el lab. `verificar-backup.sh` los comprueba al crearlos y al restaurarlos: sin manifiesto, con un fichero ausente, un checksum distinto, un nº de adjuntos que no cuadra o de otro entorno, sale con código 1 y `ERROR: ...`. Nunca se da por completo un respaldo que no pasa esa verificación.

Los `.dump` sueltos anteriores a AV-328 solo contienen la base; siguen en S3 hasta caducar y `restaurar-backup.sh` los rechaza.

## Ensayar la restauración (aislado)

No toca el entorno real: crea un contenedor PostGIS y un volumen temporales sin red, restaura ambos componentes y comprueba que cada `clave` de `core_archivo` y `ruta_almacenamiento` de `mod05_archivo` existe en los adjuntos con su SHA-256.

```sh
ssh deploy@<ip>
docker run --rm amazon/aws-cli:2.22.35 s3 ls "s3://<bucket>/backups/prod/"
/opt/konoha/infra/scripts/probar-restauracion.sh prod backups/prod/<fecha>
```

Hazlo una vez por entrega: un backup que nunca se ha restaurado no cuenta como backup. Necesita memoria libre para un PostGIS extra (unos 300 MB): no lo hagas durante un despliegue.

## Restaurar en el mismo entorno

```sh
/opt/konoha/infra/scripts/restaurar-backup.sh prod backups/prod/<fecha>
```

1. Descarga el respaldo y lo verifica; si falla, no se toca nada.
2. Pide confirmación escribiendo el nombre del entorno.
3. Hace un respaldo del estado actual y para la api.
4. Restaura la base y sustituye el contenido del volumen de adjuntos.
5. Comprueba las referencias, levanta la api y pasa el smoke test.

## Entre entornos (prod a UAT)

**No se hace con el script**, y por diseño lo rechaza. Las filas de prod apuntan a claves `prod/...` de S3: un borrado en UAT eliminaría archivos que prod sigue sirviendo. Si de verdad hace falta:

1. Restaura en una base temporal.
2. Reescribe las claves de archivo a `uat/...` y copia esos objetos en S3.
3. Anonimiza los datos personales.
4. Solo entonces vuelca el resultado en UAT.

Coordínalo antes con el equipo.

## Permisos, retención y coste

- **Permisos**: sin secretos. El contenedor de `aws-cli` toma las credenciales del `LabInstanceProfile` de la EC2. Hace falta `s3:PutObject`, `GetObject` y `ListBucket` sobre `backups/`. `deploy` ya está en el grupo `docker`.
- **Retención**: la regla `backups` del bucket (`dias_backups`, 30 días) borra cada fichero a los 30 días; los de un mismo respaldo caducan juntos. Con el lab, descarga el de prod cada semana (`arrancar-lab.md`).
- **Espacio en el host**: el respaldo se prepara en `/var/tmp` (`BACKUP_TMP`) antes de subirlo. El script calcula base + adjuntos + 100 MB y aborta si no hay sitio libre.
- **Coste**: S3 Standard cuesta unos 0,023 USD por GB al mes. Con 3 respaldos al día por entorno (cron, arranque y previo a prod) durante 30 días, guardas unas 90 copias: `90 × (tamaño de base + adjuntos comprimidos) × 0,023`. Ejemplo: con 2 GB por copia son unos 4 USD al mes por entorno; revisa el tamaño real con `aws s3 ls --recursive --summarize`. Si los adjuntos crecen, baja `dias_backups` o la frecuencia del cron antes de que pese en el crédito del lab.
