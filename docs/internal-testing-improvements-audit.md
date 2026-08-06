# HABITAR - Auditoria para prueba interna

Fecha: 2026-08-05
Rama local: feature/internal-testing-improvements

## Diagnostico inicial

HABITAR es un monorepo Dart/Flutter con separacion por paquetes:

- `apps/mobile`: aplicacion Flutter para Android, iOS y web.
- `packages/domain`: entidades y reglas de dominio.
- `packages/application`: servicios de aplicacion y contratos de repositorios.
- `packages/data`: repositorios en memoria, persistencia local, migracion local y adaptador de Auth Supabase.
- `packages/notifications`: contratos y planificador de recordatorios.
- `packages/routine_engine`: ejecucion de rutinas paso a paso.
- `packages/habit_engine`: reglas de activacion y progreso de habitos.
- `packages/wearable_bridge`: contratos para watchOS/Wear OS.
- `packages/design_system`: tema, componentes visuales y tokens.

La app funciona como Flutter mobile con targets Android/iOS/web. No es React Native, Expo ni Capacitor. La version web existe como build Flutter web y landing/legales estaticos en `sites/habitarpy`.

## Configuracion existente

- Workspace Dart en `pubspec.yaml`.
- Flutter app en `apps/mobile` con `go_router`, `flutter_riverpod`, `supabase_flutter`, `sqlite3_flutter_libs` y paquetes internos.
- Android `applicationId`: `com.habitarpy.app`.
- Android `targetSdk`: 36.
- Android `minSdk`: `flutter.minSdkVersion`.
- Android permiso actual: `INTERNET`.
- Firma release preparada con `android/key.properties` si existe.
- Supabase Auth opcional via `SUPABASE_URL` y `SUPABASE_ANON_KEY`/publishable key.
- Persistencia local con `LocalStore`, Drift/file store y repositorios locales.
- Migracion Supabase inicial con RLS en `supabase/migrations/0001_initial_schema.sql`.
- Notificaciones: contratos, consentimiento, intensidades y scheduler en memoria.
- Smartwatch: contratos de snapshots, comandos y capacidades para watchOS/Wear OS.
- Rutinas: engine paso a paso con pausa, posponer, ayuda, saltar paso y progreso visual.
- Bienestar: check-ins y solicitudes de apoyo.
- Progreso: resumen basico en portal adulto y cards compactas.
- Varios adultos: modelo local inicial `AdultProfile` y repositorios local/memoria.

## Configuracion no encontrada

- No hay `package.json` en la raiz.
- No hay `app.json` ni `app.config.*`.
- No hay configuracion Expo ni Capacitor.
- No hay `firebase.json`, `google-services.json` ni `GoogleService-Info.plist`.
- No hay service worker fuente versionado; solo aparece `flutter_service_worker.js` dentro de `apps/mobile/build/web`, generado por build.
- No hay integracion nativa actual de `flutter_local_notifications`.
- No hay permisos Android de `POST_NOTIFICATIONS`, `VIBRATE`, `SCHEDULE_EXACT_ALARM` ni `PACKAGE_USAGE_STATS`.
- No hay bloqueo real de apps/juegos; solo se puede preparar banco de tiempo y temporizadores sin prometer control nativo.

## Errores existentes antes de implementar Fase 1

No habia errores criticos de analisis en los paquetes auditados. El arbol local ya tenia cambios sin commit de fases previas y assets de Play Store.

Advertencias conocidas:

- Varias dependencias tienen versiones nuevas incompatibles con constraints actuales.
- `flutter build appbundle --release` muestra advertencia de fuente `CupertinoIcons`, pero el build termina correctamente.

## Causa del titulo roto en Progreso

La pantalla `Progreso` usa `AdultSectionScreen(kind: 'progress')`, que renderiza `AdultPage(title: 'Progreso semanal', action: ...)`.

`AdultPage` colocaba titulo y boton de accion en un `Row` rigido. En ancho pequeno o con texto ampliado, el titulo quedaba comprimido por el boton y podia romperse visualmente por overflow/salto inadecuado.

La navegacion inferior no era la causa principal; el problema estaba en el encabezado compartido de pantallas adultas.

## Correccion realizada en Progreso

Archivo: `apps/mobile/lib/src/components/adult_shell.dart`

- El encabezado de `AdultPage` ahora usa `LayoutBuilder`.
- En pantallas compactas o con texto ampliado pasa de fila a columna.
- El titulo conserva `softWrap` y deja respirar al boton de accion.
- En tablet/escritorio mantiene la fila original con separacion estable.
- La correccion aplica a Progreso y a otras pantallas adultas sin redisenio radical.

## Pruebas agregadas

Archivo: `apps/mobile/test/adult_page_layout_test.dart`

Caso cubierto:

- `progress title remains visible on narrow screens with large text`.
- Simula pantalla estrecha y texto ampliado 1.6x.
- Verifica que `Progreso semanal` exista y no haya excepciones de layout.

## Resultado de validacion Fase 1

Dependencias:

- `dart pub get`: OK.

Analisis/lint:

- `packages/domain`: OK.
- `packages/application`: OK.
- `packages/data`: OK.
- `packages/notifications`: OK.
- `packages/routine_engine`: OK.
- `packages/habit_engine`: OK.
- `packages/wearable_bridge`: OK.
- `apps/mobile flutter analyze`: OK.

Pruebas:

- `packages/domain`: OK.
- `packages/data`: OK.
- `packages/notifications`: OK.
- `packages/routine_engine`: OK.
- `packages/habit_engine`: OK.
- `packages/wearable_bridge`: OK.
- `apps/mobile flutter test`: OK.

Build:

- `flutter build appbundle --release`: OK.
- Salida: `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.

## Migraciones

Fase 1 no crea migraciones nuevas.

## Riesgos y pendientes para siguientes fases

- Notificaciones nativas requieren dependencia/plugin y permisos Android/iOS.
- Supabase solo esta conectado para Auth; faltan repositorios remotos para datos familiares.
- Las reglas RLS iniciales existen, pero los modelos nuevos de varios adultos/horarios requieren migraciones futuras si se sincronizan remotamente.
- Banco de tiempo y beneficios aun no esta implementado como modulo completo.
- Uso de apps/juegos debe mantenerse como banco de tiempo/temporizador hasta evaluar integraciones nativas y politicas de tienda.

## Confirmacion GitHub

No se hizo `git push`.
No se abrio Pull Request.
No se modifico ningun remoto.
No se solicito autenticacion GitHub.
## Phase 2 - Programmable Routines And Step Execution

Completed locally:
- Expanded `Routine` with weekdays, schedule, estimated duration, reminder lead time, repeat policy, responsible adult, context, minimum version, benefit, reminder limits, vibration/sound/silent flags, postpone and help permissions.
- Propagated the new fields through application contracts, routine service, in-memory repositories and local persisted repositories.
- Updated routine creation UI with schedule, weekdays, repeat policy, adult responsible picker, supports and sensory notification options.
- Repaired routine player copy so it shows `Paso X de Y`, current step, estimated time, progress, pause, help and postpone according to routine permissions.
- Added safe Supabase migration `0002_routine_scheduling.sql` with additive columns and default values.
- Extended local persistence tests to prove scheduled routine metadata survives repository round-trips.

Validation:
- `dart analyze`: domain, application, data OK.
- `flutter analyze`: apps/mobile OK.
- `dart test`: domain, data, routine_engine, notifications, habit_engine, wearable_bridge OK.
- `flutter test`: apps/mobile OK.
- `flutter build appbundle --release`: OK, generated `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.

## Phase 3 - Manual Signal And Notification Planning

Completed locally:
- Extended notification contracts with manual routine signal kinds, signal limits, vibration/sound flags and signal history entries.
- Added `RoutineReminderPlanner.planManualSignal` with maximum signals per routine and minimum interval checks.
- Added `NotificationService.sendRoutineSignal` to schedule a soft signal and keep local idempotency/limit history during the app session.
- Added adult dashboard button `Enviar señal`, using the active profile's first routine and current notification preferences.
- Added tests for manual signal throttling.

Limitations kept honest:
- Signals are scheduled through the current local/in-memory scheduler abstraction; native Android/iOS notification delivery is still the next integration step.
- Signal history is session-local for now. Backend persistence and audit history belong to the multi-adult/roles backend phase.
- No full-screen alarms, app blocking, UsageStats, Screen Time APIs or smartwatch-native apps were added.

Validation:
- `dart analyze`: notifications, application OK.
- `flutter analyze`: apps/mobile OK.
- `dart test`: notifications OK.
- `flutter test`: apps/mobile OK.
- `flutter build appbundle --release`: OK, generated `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.

No GitHub push, PR, release, tag, or remote change was performed.
## Phase 4 - Agreements, Benefits And Time Bank

Completed locally:
- Added non-punitive time bank domain models: benefit kind, status, benefit entity and profile summary.
- Added `TimeBankService` with idempotent minute grants and adult-approved minute usage.
- Added in-memory and local persisted repositories for time bank benefits.
- Added route `/rewards` with visible adult screen `Acuerdos y beneficios`.
- The adult can credit minutes for starting, minimum progress or completion and register 5-minute usage.
- Added safe Supabase migration `0003_time_bank_benefits.sql` with unique idempotency index.
- Added persistence test for idempotency, available balance and used minutes.

Validation:
- `dart pub get`: OK.
- `dart analyze`: application, data OK.
- `flutter analyze`: apps/mobile OK.
- `dart test`: data OK.
- `flutter test`: apps/mobile OK.
- `flutter build appbundle --release`: OK, generated `apps/mobile/build/app/outputs/bundle/release/app-release.aab`.

Limitations kept honest:
- This is a digital time bank and approval ledger, not real app blocking.
- Native Android UsageStats / iOS Screen Time control remains future work.
- Backend RLS and multi-adult audit persistence still need Supabase implementation before open production launch.

