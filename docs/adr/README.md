# Registro de decisiones (ADR)

Una decisión de arquitectura por fichero. Este registro es el único del proyecto: las decisiones del backend y del frontend también van aquí, para que la numeración no se repita.

## Cuándo escribir un ADR

Cuando la decisión es cara de deshacer o afecta a más de un módulo: stack, formato de la API, despliegue, seguridad, estructura de datos compartida.

## Cómo

1. Copia `0000-plantilla.md` como `NNNN-titulo-en-kebab-case.md`, con el siguiente número libre.
2. Estado inicial: `propuesto`. Abre un PR y enlázalo en el canal del equipo.
3. Al aprobarse, pasa a `aceptado`. Si otro ADR lo sustituye, pasa a `sustituido por NNNN` y no se borra.

## Índice

| ADR | Título | Estado |
|---|---|---|
| [0001](0001-backend-spring-boot.md) | Backend en Spring Boot | aceptado |
| [0002](0002-repos-backend-frontend-infra.md) | Tres repositorios: backend, frontend e infra | aceptado |
| [0003](0003-despliegue-ec2-compose.md) | Despliegue en una EC2 con Docker Compose | aceptado |
| [0004](0004-formato-errores-problemdetail.md) | Formato de errores con ProblemDetail | propuesto |
| [0005](0005-claves-json-camelcase.md) | Claves JSON de la API en camelCase | aceptado |
