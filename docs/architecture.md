# Arquitectura

Habitar usa un monorepo con una app Flutter y paquetes Dart separados. La intención es mantener el producto listo para Android, iOS y web sin acoplar el dominio a una plataforma concreta.

## Capas

```text
Presentation
  apps/mobile/lib/src/features
  apps/mobile/lib/src/components

Application
  packages/application

Domain
  packages/domain
  packages/habit_engine
  packages/routine_engine

Data
  packages/data

Platform integrations
  apps/mobile/lib/src/platform
  apps/mobile/lib/src/app_environment_*.dart
  packages/notifications
  packages/wearable_bridge
```

## Responsabilidades

`domain` contiene entidades y reglas que no dependen de Flutter, Supabase ni almacenamiento local.

`application` contiene servicios de uso y contratos de repositorios. Esta capa coordina operaciones, pero no decide detalles de UI ni de infraestructura.

`data` contiene implementaciones de persistencia local, repositorios en memoria, migración local y autenticación Supabase.

`apps/mobile` contiene navegación, pantallas, composición de dependencias y adaptadores de plataforma.

`design_system` concentra tema, tokens visuales y componentes compartidos. Es una pieza sensible porque cambios aquí pueden alterar toda la interfaz.

## Estado de integración

Supabase Auth está integrado cuando existen variables de configuración. La sincronización remota completa de familias, perfiles, rutinas, hábitos y progreso todavía no está implementada; hoy esas entidades viven en repositorios locales.

## Regla de seguridad para refactors

Los cambios de organización deben preservar:

- Rutas públicas y deep links.
- Nombres de entidades y contratos.
- Comportamiento de registro, login, selector de perfiles y shells adulto/niño/adolescente.
- Persistencia local existente.
- Build web bajo `/app/`.
- Publicación de landing, privacidad y términos.
