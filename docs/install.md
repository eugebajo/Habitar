# Instalacion y ejecucion

## App movil

```powershell
cd apps/mobile
flutter pub get
flutter run
```

## Analisis y pruebas

```powershell
cd apps/mobile
flutter analyze
flutter test
flutter test integration_test
```

```powershell
cd packages/domain
dart test
```

## Supabase

1. Crear un proyecto Supabase.
2. Configurar Auth con email/password.
3. Ejecutar `supabase/migrations/0001_initial_schema.sql`.
4. Configurar variables con `--dart-define` o archivo local no versionado.

Ejemplo:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```

En Supabase nuevo, `SUPABASE_ANON_KEY` puede ser la key publica que empieza con `sb_publishable_`.

## iOS y Android

La estructura Flutter esta lista, pero este entorno no tiene Flutter instalado. En una maquina con Flutter:

```powershell
flutter doctor
flutter create --platforms=ios,android .
flutter pub get
flutter run
```

Ejecutar el ultimo bloque dentro de `apps/mobile` si se necesitan regenerar carpetas nativas.

Estado actual del entorno revisado el 2026-07-15:

- Flutter SDK detectado en `C:\Users\eugen\flutter`.
- La app ya tiene carpetas `android`, `ios` y `web`.
- Falta agregar `C:\Users\eugen\flutter\bin` al Path visible por nuevas terminales.
- Falta Android Studio/Android SDK para ejecutar en Android.
- Web preview disponible con `flutter run -d chrome`.
