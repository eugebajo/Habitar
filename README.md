# Habitar

Habitar es una aplicación de acompañamiento familiar para hábitos, rutinas, autonomía y bienestar cotidiano de niños, niñas y adolescentes.

El producto está pensado para que adultos responsables, tutores, profesionales o docentes creen el marco de acompañamiento. Los niños y adolescentes entran a una experiencia separada, simple y cuidada, donde ven lo que necesitan hacer, su progreso y las formas de pedir ayuda.

## Estado actual

- App Flutter principal en `apps/mobile`.
- Landing pública, términos y privacidad en `sites/habitarpy`.
- App web publicada en `https://habitarpy.com/app/`.
- Dominio público: `https://habitarpy.com`.
- Autenticación Supabase integrada cuando se configuran `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- Persistencia local activa: Drift/SQLite en plataformas con sistema de archivos y almacenamiento web en navegador.
- CI en GitHub Actions para app móvil y paquetes Dart.
- Flujo de publicación web por GitHub Pages.
- Preparación de Play Store en curso, pendiente de verificación de Google Play Console.

## Estructura

```text
apps/
  mobile/          App Flutter principal
  watchos/         Diseño técnico preparatorio para watchOS
  wearos/          Diseño técnico preparatorio para Wear OS
packages/
  domain/          Entidades y reglas centrales
  application/     Casos de uso y contratos de repositorios
  data/            Persistencia local, Auth Supabase y adaptadores
  design_system/   Tema visual, tokens y componentes compartidos
  routine_engine/  Motor de rutinas guiadas
  habit_engine/    Políticas de hábitos
  notifications/   Contratos de recordatorios
  story_library/   Biblioteca de cuentos y actividades
  wearable_bridge/ Contratos para relojes
  analytics_core/  Eventos analíticos
  accessibility/   Preferencias de accesibilidad
sites/
  habitarpy/       Sitio público y salida web publicada
supabase/
  migrations/      Esquema inicial de base de datos
docs/              Documentación de producto, arquitectura y lanzamiento
scripts/           Automatizaciones locales
```

Más detalle: `docs/project-structure.md`.

## Desarrollo local

```powershell
cd apps/mobile
flutter pub get
flutter run
```

Para abrir la app web local:

```powershell
cd apps/mobile
flutter run -d chrome
```

## Verificación

Checks completos:

```powershell
.\scripts\checks.ps1
```

Checks principales de la app:

```powershell
cd apps/mobile
flutter analyze
flutter test
flutter build web --release --base-href /app/
```

## Supabase

La app lee estas variables en build/runtime:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

En GitHub Pages:

- `SUPABASE_URL` va como variable del entorno `github-pages`.
- `SUPABASE_ANON_KEY` va como secreto del entorno `github-pages`.

La publishable key de Supabase no es una service role key, pero igual debe tratarse con cuidado y no escribirse directamente en el código.

Más detalle: `docs/authentication.md` y `docs/data-flow.md`.

## Publicación

- Web pública: GitHub Pages desde `.github/workflows/habitarpy-pages.yml`.
- CI: `.github/workflows/ci.yml`.
- Android: preparación de Play Store en curso.
- iOS: pendiente de preparación específica para App Store Connect.

Más detalle: `docs/deployment.md`.

## Documentación útil

- `docs/architecture.md`
- `docs/project-structure.md`
- `docs/routing.md`
- `docs/data-flow.md`
- `docs/authentication.md`
- `docs/testing.md`
- `docs/deployment.md`
- `docs/development-guide.md`
- `docs/mvp-status.md`
