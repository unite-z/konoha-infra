# 0004. Formato de errores con ProblemDetail

- Estado: propuesto
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

El backend responde los errores en varios formatos:

- MOD-05 (`ErroresControllerAdvice`): `{codigo, detalle}` para el dominio; `{campo: [mensajes]}` para la validación; `{detail}` para la autenticación.
- MOD-06 (`ManejadorExcepciones` y el paquete `api/drf`): `{codigo, detalle}` para el dominio, y el formato heredado de DRF para el resto.

El frontend tiene que entender todos.

## Decisión

Formato único para todo el código nuevo: **ProblemDetail (RFC 9457)**, que Spring 6 trae de serie, con `Content-Type: application/problem+json`:

```json
{
  "type": "about:blank",
  "title": "Transición no permitida",
  "status": 409,
  "detail": "La atención ya está finalizada; no admite un nuevo inicio.",
  "instance": "/api/v1/tercerizados/atenciones/18/inicio/",
  "codigo": "transicion-no-permitida",
  "errores": { "fecha_inicio": ["Debe ser anterior a la fecha de fin"] }
}
```

- `codigo`: estable y en kebab-case. Es lo que lee el frontend; `title` y `detail` son para las personas.
- `errores`: solo en la validación, por campo.
- Un único `@RestControllerAdvice` global.

## Alternativas descartadas

- Mantener `{codigo, detalle}`: es sencillo, pero propio, y obliga a documentar a mano cada variante.

## Consecuencias

- Mientras esté en `propuesto`, `api.md` lo marca como formato objetivo para el código nuevo.
- La migración de MOD-05 y MOD-06 va en tickets aparte, coordinada con el frontend (que acepte ambos formatos durante la transición).
