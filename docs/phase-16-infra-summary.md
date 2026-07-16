# Fase 16 infraestructura: Drift/SQLite real

## Implementado

- Dependencias `drift` y `sqlite3` en `packages/data`.
- Dependencia `sqlite3_flutter_libs` en la app Flutter.
- `DriftLocalStore` sobre SQLite con tabla `local_records`.
- Arranque productivo en plataformas `dart:io` usando `habitar.sqlite`.
- Repositorios locales existentes funcionando sobre el contrato `LocalStore`.
- Tests de persistencia SQLite en archivo y memoria.

## Decision

Se implemento Drift como backend real compatible con el contrato actual antes de normalizar todas las tablas. Esto permite pasar de JSON a SQLite sin reescribir cada repositorio en la misma fase.

## Pendiente

- Crear tablas Drift tipadas por entidad.
- Migrar datos existentes desde `habitar_store.json` hacia `habitar.sqlite`.
- Reemplazar la tabla generica `local_records` por tablas normalizadas de forma gradual.
