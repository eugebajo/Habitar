# Fase 14: Preparacion Drift/SQLite

## Implementado

- `PersistenceMigrationPlan` para migrar de JSON local a Drift/SQLite.
- Mapeo explicito de colecciones actuales a tablas Drift.
- Clasificacion de tablas sincronizables y tablas solo locales.
- Pruebas que verifican cobertura de todas las colecciones de `LocalStoreCollections`.

## Decisiones

- No se agrego aun `drift`, `sqlite3_flutter_libs` ni `build_runner` para evitar generacion nativa prematura.
- La migracion queda definida como contrato verificable antes de escribir el database generado.
- `sync_queue` y `auth_state` quedan como tablas locales no sincronizables.

## Pendiente

- Agregar dependencias Drift y generar `HabitarDatabase`.
- Crear migrador JSON -> SQLite idempotente.
- Reemplazar `FileLocalStore` por repositorios Drift.
- Medir tiempo de migracion con datos demo antes de beta.
