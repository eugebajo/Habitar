# Testing

## Checks locales

Ejecutar todo:

```powershell
.\scripts\checks.ps1
```

La rutina ejecuta:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `dart pub get`
- `dart analyze`
- `dart test` en paquetes con carpeta `test`

## Checks de app

```powershell
cd apps/mobile
flutter analyze
flutter test
flutter build web --release --base-href /app/
```

## Checks de paquetes

```powershell
cd packages/domain
dart analyze
dart test
```

## Antes de refactors grandes

Antes de dividir archivos como `portal_screens.dart`, `local_repositories.dart` o `design_system.dart`, agregar o confirmar tests de caracterización para:

- Selector de perfiles.
- Entrada adulto/niño/adolescente.
- Registro y login.
- Persistencia local.
- Creación y ejecución de rutina.
- Creación y seguimiento de hábitos.
