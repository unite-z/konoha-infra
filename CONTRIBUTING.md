# Cómo contribuir

Vale para los tres repos. Cada uno añade en su propio `CONTRIBUTING.md` lo que le es específico.

## Antes de empezar

1. Ten un issue en Linear asignado (`AV-<n>`).
2. Instala los hooks del repo, una vez por clon:

   ```sh
   git config core.hooksPath .githooks
   ```

   Si tienes [gitleaks](https://github.com/gitleaks/gitleaks) instalado, el hook revisa los secretos antes de cada commit. Si no, lo hace CI.

## Ciclo de trabajo

```sh
git switch main && git pull
git switch -c feat/AV-12-registro-de-poda
# ... trabajo, pruebas en local ...
git commit -m "feat(AV-12): agrega registro de poda por ejemplar"
git push -u origin feat/AV-12-registro-de-poda
```

Después:

1. Abre el PR, como borrador si aún no está listo. El título lleva el formato del commit.
2. Rellena la plantilla.
3. Espera `ci-ok` en verde y una aprobación.
4. Fusiona con **squash**.

## Lo que no se negocia

- Nada de push directo a `main`.
- Ningún secreto en el repo.
- No se editan migraciones ya fusionadas.
- El backend comprueba los permisos; la interfaz solo oculta.
- Nombres en kebab-case, salvo las excepciones de [nombres.md](docs/estandares/nombres.md).
- No se fusiona en `main` el viernes antes de la reunión de las 15:30.

Detalle completo en [git-y-prs.md](docs/estandares/git-y-prs.md).
