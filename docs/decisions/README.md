# Decisiones de arquitectura

Las decisiones formales existentes viven en `docs/adr`.

Este directorio queda como índice de lectura rápida para nuevas decisiones de producto y arquitectura que aparezcan durante la preparación de lanzamiento.

## Decisiones vigentes

- Mantener monorepo con app Flutter y paquetes Dart.
- Separar landing pública de app web.
- Publicar la app web bajo `/app/`.
- Mantener dominio propio de Habitar separado de ASULUGAR.
- Usar Supabase Auth como proveedor de autenticación.
- Mantener persistencia local usable mientras se completa sincronización remota.
- No construir soporte genérico para cualquier smartwatch; preparar contratos específicos para watchOS y Wear OS.

## ADR existentes

- `docs/adr/0001-architecture.md`
- `docs/adr/0002-gradual-habit-activation.md`
- `docs/adr/0003-wearable-scope.md`
