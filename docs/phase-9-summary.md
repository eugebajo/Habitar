# Fase 9: Conexion de persistencia local a la app

## Implementado

- Arranque Flutter asincronico con `buildProductionOverrides`.
- En plataformas `dart:io`, la app usa `FileLocalStore` en el directorio de soporte de la aplicacion.
- En web, previews y entornos sin sistema de archivos, la app conserva repositorios en memoria.
- `FileLocalStore` se separo en export condicional para no arrastrar `dart:io` al build web.
- Repositorios locales conectados en produccion: auth local, familia, perfiles, rutinas, sesiones, habitos y progreso.

## Verificado

- `flutter analyze`.
- `flutter test`.
- `flutter build web --debug`.
- `dart test` en `packages/data`.

## Pendiente

- Mostrar en UI un estado de "datos guardados en este dispositivo".
- Persistir check-ins emocionales, apoyos, cuentos, notificaciones y wearables.
- Definir migracion desde JSON a Drift/SQLite.
- Agregar sync queue local-remota antes de Supabase real.
