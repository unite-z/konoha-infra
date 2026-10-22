# Restaurar un backup

Los backups están en `s3://<bucket>/backups/<entorno>/<fecha>.dump`. Se generan:

- antes de cada despliegue a prod;
- cada día a las 13:00;
- 10 minutos después de arrancar el lab.

Se conservan 30 días.

## Restaurar en el mismo entorno

```sh
ssh deploy@<ip>
docker run --rm amazon/aws-cli:2.22.35 s3 ls "s3://<bucket>/backups/prod/" | tail -5
/opt/konoha/infra/scripts/restaurar-backup.sh prod backups/prod/<fecha>.dump
```

El script:

1. Pide confirmación escribiendo el nombre del entorno.
2. Hace un backup del estado actual.
3. Para la api y restaura la base.
4. Vuelve a levantar la api y pasa el smoke test.

## Entre entornos (prod a UAT)

**No se hace con el script**, y por diseño lo rechaza. Las filas de prod apuntan a claves `prod/...` de S3: un borrado en UAT eliminaría archivos que prod sigue sirviendo. Si de verdad hace falta:

1. Restaura en una base temporal.
2. Reescribe las claves de archivo a `uat/...` y copia esos objetos en S3.
3. Anonimiza los datos personales.
4. Solo entonces vuelca el resultado en UAT.

Coordínalo antes con el equipo.

## Probarlo

Una vez por entrega, restaura el último backup de prod en tu máquina (PostGIS en Docker) y comprueba que la api arranca con él. Un backup que nunca se ha restaurado no cuenta como backup.
