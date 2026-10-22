# 0005. Claves JSON de la API en camelCase

- Estado: aceptado
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

MOD-05 y MOD-06 responden en snake_case, herencia de su primera versión en Django REST Framework. Jackson usa camelCase por defecto, y en TypeScript es lo natural.

## Decisión

- **camelCase** es el formato objetivo de las claves JSON.
- Los módulos nuevos nacen en camelCase.
- MOD-05 y MOD-06 siguen en snake_case hasta su migración, para no mezclar formatos dentro de un mismo módulo. Los endpoints nuevos de esos módulos siguen el formato de su módulo mientras tanto.
- Las claves de paginación (`count`, `next`, `previous`, `results`) son de una sola palabra y no cambian.

## Consecuencias

- Deuda registrada en un ticket: migrar MOD-05 y MOD-06 a camelCase, de forma coordinada con el frontend.
- Mientras dure, la API tiene dos formatos según el módulo. OpenAPI documenta el de cada uno.
