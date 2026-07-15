# Fase 8: Persistencia local inicial

## Implementado

- `FileLocalStore` durable basado en JSON para desarrollo y prototipos.
- Repositorios locales para usuario actual, familia, perfiles, rutinas, sesiones, habitos y progreso de habitos.
- Serializacion de metadatos, reglas de acceso, rutinas con pasos y sesiones activas.
- Pruebas que verifican lectura despues de recrear el store, simulando reinicio de app.

## Decisiones

- Se mantiene `InMemory*Repository` para previews rapidas y tests de UI.
- La persistencia local real queda detras de los mismos contratos de `application`.
- No se introduce Drift todavia para evitar generacion y complejidad nativa antes de cerrar el modelo de sincronizacion.

## Pendiente

- Conectar `FileLocalStore` a la app movil usando una ruta de documentos de la plataforma.
- Migrar de JSON a Drift/SQLite antes de beta con datos reales.
- Persistir notificaciones, check-ins emocionales, apoyos, cuentos y wearables en repositorios locales equivalentes.
- Agregar cola de sincronizacion local-remota con Supabase.
