# Estructura del proyecto

## Raíz

```text
.github/workflows/      CI y despliegue web
apps/                   Aplicaciones por plataforma
docs/                   Documentación técnica y de lanzamiento
packages/               Paquetes Dart reutilizables
scripts/                Comandos auxiliares
sites/                  Sitio público
supabase/migrations/    Esquema SQL inicial
```

## App móvil

```text
apps/mobile/lib/main.dart
apps/mobile/lib/src/app.dart
apps/mobile/lib/src/dependencies.dart
apps/mobile/lib/src/app_environment.dart
apps/mobile/lib/src/app_environment_io.dart
apps/mobile/lib/src/app_environment_web.dart
apps/mobile/lib/src/features/
apps/mobile/lib/src/components/
apps/mobile/lib/src/platform/
```

`app.dart` define las rutas principales con GoRouter. `dependencies.dart` compone servicios y repositorios. Los archivos `app_environment_*` eligen persistencia y configuración según plataforma.

## Paquetes

`packages/domain`: entidades y políticas centrales.

`packages/application`: servicios de caso de uso y contratos de repositorios.

`packages/data`: implementaciones locales, Supabase Auth y migración de almacenamiento.

`packages/design_system`: tema visual y componentes compartidos.

`packages/routine_engine` y `packages/habit_engine`: reglas específicas de rutinas y hábitos.

`packages/notifications`, `packages/wearable_bridge`, `packages/story_library`, `packages/accessibility` y `packages/analytics_core`: módulos especializados.

## Archivos grandes identificados

Estos archivos conviene tratar con cuidado en fases pequeñas:

- `apps/mobile/lib/src/features/portal/portal_screens.dart`
- `packages/data/lib/src/local_repositories.dart`
- `packages/design_system/lib/design_system.dart`
- `packages/data/lib/src/in_memory_repositories.dart`

La prioridad no es moverlos de inmediato, sino cubrirlos con documentación y tests antes de dividirlos.
