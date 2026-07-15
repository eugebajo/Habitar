# Como ver la app

Este entorno no tiene `flutter` ni `dart` disponibles en PATH, por eso Codex no puede abrir la app aqui.

En una maquina con Flutter instalado:

```powershell
cd C:\Users\eugen\OneDrive\Documentos\Habitar\apps\mobile
flutter pub get
flutter run
```

Mientras no tengas Android Studio/Android SDK instalado, podes verlo en Chrome:

```powershell
cd C:\Users\eugen\OneDrive\Documentos\Habitar\apps\mobile
flutter run -d chrome
```

Para verlo como app Android, primero instala Android Studio y acepta los componentes del Android SDK. Despues:

```powershell
flutter doctor
flutter run
```

Flujo disponible:

1. Registro del adulto.
2. Creacion de perfil infantil o adolescente.
3. Panel semanal.
4. Gestion de habitos.
5. Creacion de rutina guiada.
6. Ejecucion infantil de rutina.
7. Configuracion de recordatorios.
8. Check-in emocional.
9. Biblioteca de cuentos.
10. Preparacion de wearables.

Pantallas principales:

- `apps/mobile/lib/src/features/adult_registration/adult_registration_screen.dart`
- `apps/mobile/lib/src/features/profile_setup/profile_setup_screen.dart`
- `apps/mobile/lib/src/features/family_dashboard/family_dashboard_screen.dart`
- `apps/mobile/lib/src/features/habit_setup/habit_setup_screen.dart`
- `apps/mobile/lib/src/features/routine_setup/routine_setup_screen.dart`
- `apps/mobile/lib/src/features/routine_player/routine_player_screen.dart`
- `apps/mobile/lib/src/features/notification_settings/notification_settings_screen.dart`
- `apps/mobile/lib/src/features/wellbeing_checkin/wellbeing_checkin_screen.dart`
- `apps/mobile/lib/src/features/story_library/story_library_screen.dart`
- `apps/mobile/lib/src/features/wearables/wearables_screen.dart`
