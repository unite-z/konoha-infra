# Transferir los repos a la organización

> Hecho el 22-10-2026: los tres repos están en `unite-z`, públicos, y UAT corre imágenes de `ghcr.io/unite-z`. Se conserva como referencia.

Los tres repos nacen privados en la cuenta personal de Marcos y se mueven a la organización del curso (`unite-z`) cuando haya acceso. Transferir conserva el historial, los issues, los PR y los colaboradores.

## Requisitos previos

1. Marcos es miembro de `unite-z` con permiso para crear repositorios (o es owner).
2. Un owner de `unite-z` borra o renombra los repos vacíos `konoha-backend`, `konoha-frontend` y `konoha-infra`. No puede haber dos repos con el mismo nombre.
3. No hay despliegues en curso ni PR a punto de fusionarse.

## Pasos (para cada repo, empezando por `konoha-infra`)

1. Settings, General, Danger Zone, **Transfer ownership**. Destino: `unite-z`. Escribe el nombre del repo para confirmar.
2. Comprueba en el repo transferido lo siguiente:
   - Colaboradores y permisos (Settings, Collaborators). En la organización conviene pasar a un equipo `konoha` con permiso de escritura.
   - Secrets y variables de Actions. Recrea los que falten (lista en `docs/estandares/seguridad-secretos.md`).
   - Rulesets de `main`. Si no están, aplícalos con `.github/rulesets/README.md`.
   - Webhooks y deploy keys.
3. Actualiza el remoto en cada clon local:

   ```sh
   git remote set-url origin https://github.com/unite-z/<repo>.git
   ```

   GitHub redirige las URLs antiguas, pero no conviene depender de eso.
4. **Imágenes de GHCR**: no se mueven con el repo. Tras la transferencia:
   - Fusiona cualquier cambio (o lanza el workflow de build a mano) para publicar `ghcr.io/unite-z/konoha-api` y `konoha-web`.
   - Genera un token de solo lectura de paquetes para la organización y actualiza `GHCR_TOKEN_LECTURA` y `REGISTRO_IMAGENES` en el `.env` del host (ver `desplegar.md`).
   - Despliega UAT y comprueba el smoke test antes de promover a prod.
   - Borra los paquetes antiguos de la cuenta personal cuando prod ya corra la imagen nueva.
5. Si la organización usa el plan gratuito, los rulesets en repos privados no se aplican: o se hacen públicos, o se mantiene un plan que los soporte.

## Comprobación final

- [ ] Los tres repos están en `unite-z` y la cuenta personal no conserva copias.
- [ ] CI en verde en un PR de prueba.
- [ ] UAT y prod corren imágenes de `ghcr.io/unite-z/...`.
- [ ] `promover-prod.yml` funciona desde `konoha-infra`.
