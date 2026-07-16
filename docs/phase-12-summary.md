# Fase 12: Cola de sincronizacion local-remota

## Implementado

- Contratos `SyncQueueItem`, `SyncQueueRepository`, `SyncOperation` y `SyncQueueStatus`.
- `SyncService` para registrar cambios locales y marcar resultados de sincronizacion.
- `LocalSyncQueueRepository` persistente sobre `LocalStore`.
- `InMemorySyncQueueRepository` para previews y tests.
- Provider mobile `syncServiceProvider` y override productivo con store local.
- Pruebas de transiciones `pending`, `failed` y `pushed`.

## Pendiente

- Worker de subida real contra Supabase.
- Politica de reintentos/backoff.
- Resolucion de conflictos local-remoto.
- Registro automatico de cambios desde cada repositorio local.
