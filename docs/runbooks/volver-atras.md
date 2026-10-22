# Volver atrás

## Automático

`deploy.sh` vuelve solo a la versión anterior si los contenedores no quedan sanos, si el digest no coincide o si falla el smoke test. El workflow queda en rojo y avisa en Discord.

## A mano

Cuando el despliegue pasó las comprobaciones pero hay un error funcional:

```sh
ssh deploy@<ip> /opt/konoha/infra/scripts/volver-atras.sh prod   # o uat
```

Vuelve a la versión de `version.env.anterior`. Para ir a una versión concreta que ya pasó por UAT, usa `promover-prod.yml` con sus SHA.

## Lo que la vuelta atrás no deshace

- **Migraciones**: la base se queda como está. Por eso todas tienen que ser compatibles con la versión anterior (expand/contract, en `base-datos.md` del backend).
- Si una migración rompió datos, restaura el backup previo al despliegue: `restaurar-backup.md`.

## Después

1. Abre un issue `tipo-bug` con lo que pasó y enlaza el workflow.
2. La corrección entra por el flujo normal (PR, UAT, prod). Nada de parches a mano en el host.
