# 0001. Backend en Spring Boot

- Estado: aceptado
- Fecha: 2026-10-22
- Ticket: AV-1

## Contexto

Los documentos del curso dejaban abierto el backend entre Django (con GeoDjango y PostGIS) y Spring Boot. El borrador de código de MOD-05 y MOD-06 ya está escrito en Java 21 con Spring Boot 3.5, y la Estrategia y el Plan de Adquisiciones del equipo nombran Spring Boot.

## Decisión

El backend es **Spring Boot 3.5 con Java 21**, con Maven wrapper, Spring JDBC, Flyway, Spring Security, springdoc y el SDK `google-genai`. Un solo servicio para todos los módulos, con un paquete por módulo (`pe.edu.pucp.areasverdes.modNN`).

## Alternativas descartadas

- Django con GeoDjango: mejor soporte geoespacial y admin gratuito, pero obligaba a reescribir el borrador.

## Consecuencias

- Se aprovecha el código existente y su suite de pruebas.
- Se pierde el admin de Django: los catálogos de RNF-011 necesitan pantallas propias en el frontend.
- Sin ORM: el SQL geoespacial (PostGIS) se escribe a mano con `ST_*` y se prueba contra PostGIS real.
- La JVM pide más memoria que un proceso Python: límites de memoria y `MaxRAMPercentage=65` en ADR 0003.
