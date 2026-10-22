# 0005. Claves JSON de la API en snake_case

- Estado: aceptado
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

MOD-05 y MOD-06 responden en snake_case, herencia de su primera versión en Django REST Framework. El frontend ya consume ese contrato. Jackson usa camelCase por defecto.

## Decisión

- **snake_case es obligatorio** en las claves JSON de toda la API, en la entrada y en la salida: `fecha_inicio`, `numero_orden_compra`.
- Se configura de forma global en Spring: `spring.jackson.property-naming-strategy=SNAKE_CASE`. Los campos Java siguen en camelCase y Jackson los traduce. Con las 235 pruebas existentes se comprobó que no rompe nada: MOD-05 ya usa nombres en snake_case y los mapas no se ven afectados.
- Los parámetros de consulta (`?area_verde_id=3`) también van en snake_case.

## Alternativas descartadas

- camelCase (el defecto de Jackson y lo habitual en TypeScript): obligaba a migrar los contratos de MOD-05 y MOD-06 y todo el frontend que los consume, sin beneficio funcional.

## Consecuencias

- En el frontend, los tipos de `src/types/` usan claves en snake_case. Es la única excepción a camelCase en TypeScript y se limita a los datos de la API.
- Deuda sin cambio de contrato:
  - MOD-05 nombra los componentes de sus `record` en snake_case para conseguir el formato. Con la estrategia global ya no hace falta, y pasarán a camelCase cuando se toquen;
  - MOD-06 serializa a mano con mapas (`Serializadores`).
