# Git y pull requests

Aplica a `konoha-backend`, `konoha-frontend` y `konoha-infra`.

## Tickets

- Todo trabajo tiene un issue en Linear antes de crear la rama.
- Prefijo: **`AV`** (`AV-12`). El primer issue, AV-1, es «Estándares, CI y despliegue, Sprint 0». Si cambia, se actualiza aquí y en la variable `PREFIJO_TICKET` de GitHub Actions; nada más lo fija.
- Poner el ID en la rama y en el título del PR enlaza el PR con el issue de Linear.

## Ramas

```
<tipo>/<ID>-<descripcion-corta>
feat/AV-12-registro-de-poda
fix/AV-31-filtro-sector-vacio
chore/AV-40-actualiza-spring-boot
```

- `tipo`: `feat` (funcionalidad), `fix` (corrección) o `chore` (mantenimiento, docs, CI, dependencias).
- Una rama por ticket, creada desde `main` actualizado (`git switch main && git pull && git switch -c ...`).
- Vida corta: si pasa de tres días, se parte el ticket.
- En tu propia rama puedes reescribir historia (`git push --force-with-lease`). En `main`, nunca.

## Commits

```
tipo(ID): descripción en español
feat(AV-12): agrega registro de poda por ejemplar
```

- Tipos: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`.
- Máximo 72 caracteres en la primera línea, en minúscula y sin punto final.
- Verbo en tercera persona, como el resto del historial: «agrega», «corrige», «elimina».
- El cuerpo (opcional) explica el porqué, no el qué.
- Sin ficheros generados, `.env`, volcados de base ni binarios pesados.

## Pull requests

- **Título = mensaje del squash**, con el mismo formato del commit: `feat(AV-12): agrega registro de poda por ejemplar`. CI lo valida.
- Rellena la plantilla: qué y por qué, pruebas, migraciones, capturas si cambia la interfaz y riesgos con su vuelta atrás.
- Abre el PR pronto como borrador. Pásalo a «Ready for review» cuando CI esté en verde.
- Tamaño orientativo: menos de 400 líneas cambiadas sin contar tests ni ficheros generados. Si no, se parte.
- Para fusionar hacen falta:
  - el check `ci-ok` en verde;
  - las conversaciones resueltas.
- Cada persona puede fusionar su propio PR. La revisión de otra persona (o de quien figure en `CODEOWNERS` para lo tocado) es recomendable, sobre todo si hay migraciones, permisos o cambios del contrato de la API, pero no obligatoria.
- Se fusiona **solo con squash**. La rama se borra sola al fusionar.
- Quien revisa comenta con intención: `bloqueante:` (hay que cambiarlo), `sugerencia:` o `pregunta:`.
- Para deshacer algo ya fusionado: `git revert` en una rama nueva y PR. Nunca se reescribe `main`.

## Calendario

- Fusionar en `main` despliega en UAT automáticamente.
- **No se fusiona en `main` el jueves desde las 18:00 (hora de Lima), cuando empieza la reunión del equipo.** UAT tiene que estar estable durante la reunión. Antes de esa hora, el jueves se fusiona con normalidad.
- La promoción a prod es manual (`promover-prod.yml` en `konoha-infra`) y la decide quien coordina la entrega.

## Reglas de `main`

Definidas en `.github/rulesets/main.json` de cada repo (cómo se aplican en `.github/rulesets/README.md`):

- sin push directo ni force push;
- PR obligatorio, sin aprobación mínima: quien abre el PR puede fusionarlo;
- conversaciones resueltas;
- check `ci-ok` obligatorio;
- historia lineal (solo squash).

## Minutos de GitHub Actions

Los repos son privados y la cuenta tiene un cupo mensual (unos 3.000 minutos). Para no agotarlo:

- `ci.yml` usa `concurrency` con `cancel-in-progress: true`: un push nuevo cancela la ejecución anterior del mismo PR. Los workflows de despliegue **no** cancelan nunca (`cancel-in-progress: false`).
- Caché de `~/.m2` en el backend y de npm en el frontend.
- Cada job pesado solo corre si cambia su parte (código, dependencias o el propio workflow). El job `ci-ok` corre siempre y es el único check obligatorio.
- Los PR en borrador también ejecutan CI: si vas a hacer muchos pushes seguidos, agrúpalos.
- El consumo se revisa en Settings, Billing. Si se acerca al límite, se avisa en el canal del equipo.
