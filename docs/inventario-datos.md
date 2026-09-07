# Inventario de datos de Habitar

Auditoría del código y las migraciones de Supabase para servir de base a la política de privacidad y al
cuestionario de seguridad de datos de Google Play. Cada afirmación cita el archivo o la migración donde se
verificó. Donde no pude confirmar algo desde el código, lo digo explícitamente en vez de suponerlo.

**Auditado sobre:** commit `d57bb15`, `apps/mobile/pubspec.yaml` versión `0.1.5+12`, 2026-09-07.
**Application ID:** `com.habitarpy.app` (`apps/mobile/android/app/build.gradle.kts:23`). Dominio de soporte:
`habitarpy.com`, contacto `soporte@habitarpy.com` (`sites/habitarpy/CNAME`,
`sites/habitarpy/privacy/index.html:38`).

**Ya existe una política de privacidad publicada** en `sites/habitarpy/privacy/index.html`, marcada como
"versión preliminar" del 23 de julio de 2026 — genérica, sin el detalle por tabla que este inventario aporta.
También existe ya una página de eliminación de cuenta en `sites/habitarpy/account-deletion/index.html`
(proceso por correo, ver Parte 5). Este documento no reemplaza esas páginas; les da la base factual para
reescribirlas con precisión.

---

## 1. Qué se recolecta

Fuente: las 11 migraciones en `supabase/migrations/` (falta la 0009 — fue renombrada a 0011, no es una
migración perdida; el comentario de `supabase/migrations/0011_family_activity_events.sql:7` lo explica) más
las pantallas de `apps/mobile/lib/src/features/` que escriben cada tabla.

**Cómo leer "quién puede ver":** todas las tablas familiares están protegidas por Row Level Security. La regla
que se repite en casi todas (`supabase/migrations/0001_initial_schema.sql`, endurecida en
`0007_role_permissions_hardening.sql`) es: **cualquier adulto miembro de la familia puede leer** (roles
`owner`, `parent`, `caregiver`, `professional` o `viewer` — ver política "family members can view profiles",
`0007_role_permissions_hardening.sql:15-25`), pero **solo `owner`, `parent` o `caregiver` pueden escribir**.
Es decir: un adulto invitado como `professional` o `viewer` ve el nombre, la edad y toda la actividad del
niño, aunque no pueda modificarla. Esto es relevante para la política porque el conjunto de "quién ve los
datos del menor" es más amplio que "quién es el tutor".

### Datos de un adulto (cuenta)

| Dato | Dónde se guarda | Quién lo ve | Fuente |
|---|---|---|---|
| Email y contraseña | `auth.users` (gestionado por Supabase Auth/GoTrue, no por una tabla propia) | Nadie dentro de la app; el proveedor de autenticación | Formulario de registro, `apps/mobile/lib/src/features/adult_registration/adult_registration_screen.dart:78-91`; llamada real vía `client.auth.signUp`, `apps/mobile/lib/src/platform/supabase_flutter_auth_gateway.dart:19-38` |
| Nombre del adulto | `auth.users.user_metadata.display_name` (metadata de Supabase Auth, no una columna propia) | Miembros de la misma familia (se resuelve al mostrar quién invitó, quién aprobó, etc.) | `supabase_flutter_auth_gateway.dart:26` (`data: {'display_name': displayName}`) |
| Nombre de la familia | `families.name` | Miembros de la familia | `create_initial_family`, `supabase/migrations/0005_initial_family_bootstrap.sql:4-74` |
| Rol del adulto en la familia | `family_members.role` (`owner`, `parent`, `caregiver`, `professional`, `viewer`) | Miembros de la familia | `0001_initial_schema.sql:17-24`, ampliado en `0004_family_invitations_and_routine_overrides.sql:5-10` |
| Email de un adulto invitado (antes de aceptar) | `adult_invitations.email` | Miembros de la familia que invitó, y el propio invitado (por coincidencia de email de su JWT) | `0004_family_invitations_and_routine_overrides.sql:12-23`; también vía código de invitación en `0010_invitation_codes.sql` (el email igual queda en la tabla; lo que cambia es el mecanismo de aceptación) |
| Perfil de adulto local (nombre, email, rol) | Solo el dispositivo — tabla local `adult_profiles`, nunca Supabase (ver Parte 3) | Nadie fuera del dispositivo | `AdultProfile`, `packages/domain/lib/src/entities.dart:196-211`; `adultProfileRepositoryProvider` está fijado a `LocalAdultProfileRepository(store)` sin condición en `apps/mobile/lib/src/app_environment_io.dart:46-47` y `app_environment_web.dart` (no hay una versión Supabase de este repositorio) |

### Datos de un niño o adolescente

| Dato | Dónde se guarda | Quién lo ve | Es de un menor |
|---|---|---|---|
| Apodo/nombre para dirigirse a él ("¿Cómo quiere que le llamemos?") | `profiles.display_name` | Cualquier adulto de la familia (cualquier rol) | Sí |
| Edad (3 a 17, no fecha de nacimiento) | `profiles.age`, con `check (age between 3 and 17)` | Cualquier adulto de la familia | Sí |
| Tipo de perfil (niño/adolescente) | `profiles.kind` | Cualquier adulto de la familia | Sí |
| Preferencia de reflexión privada | `profiles.private_reflection_enabled` | Cualquier adulto de la familia | Sí |
| Título de cada rutina y de cada paso | `routines.title`, `routine_steps.title` | Cualquier adulto de la familia | Sí (describe la vida cotidiana del menor) |
| Horario, días, duración, recordatorios de cada rutina | `routines.scheduled_hour/minute`, `weekdays`, `estimated_duration_minutes`, `lead_reminder_minutes`, `repeat_policy`, etc. | Cualquier adulto de la familia | Sí |
| Progreso de cada sesión de rutina (pasos completados/saltados, pausas, ayuda pedida) | `routine_sessions.completed_step_ids`, `skipped_step_ids`, `pause_reason`, `help_requested`, `postponed_until` | Cualquier adulto de la familia | Sí — es historial de actividad del menor, hora por hora |
| Evento de "rutina completada" (para el feed de actividad familiar) | `family_activity_events` (nombre del perfil y título de rutina copiados como snapshot en el momento del evento) | Cualquier adulto de la familia, solo lectura | Sí — `supabase/migrations/0011_family_activity_events.sql:44-56` |
| Ajuste puntual de un día ("pausar hoy", "vamos tarde", "día de descanso", "cambiar horario de hoy") | `routine_overrides.override_type`, `note` (el `note` es siempre uno de 4 textos fijos que pone la app, no texto libre — verificado en `apps/mobile/lib/src/features/portal/portal_screens.dart:557-591`) | Cualquier adulto de la familia | Sí |
| Hábitos en seguimiento (título, estado) | `habits.title`, `habit_status` | Cualquier adulto de la familia | Sí |
| Minutos de "banco de tiempo" ganados/usados (recompensa no punitiva) | `time_bank_benefits` (descripción, minutos, límite diario, vencimiento) | Cualquier adulto de la familia | Sí |
| Pedido de ayuda / pausa / más tiempo durante una rutina | `support_requests.kind`, `note` (el `note` también es generado por la app — solo IDs de sesión/rutina/paso, verificado en `packages/application/lib/src/routine_service.dart:285-292` — **nunca texto escrito por el niño**) | Cualquier adulto de la familia | Sí |
| **Check-in emocional** (estado de ánimo, nivel de energía, nivel de sobrecarga, si necesita silencio o movimiento) | **Solo el dispositivo.** La tabla `emotion_check_ins` existe en Supabase (`0001_initial_schema.sql:136-150`) pero **no hay ningún repositorio que la use** — `emotionCheckInRepositoryProvider` está fijado incondicionalmente a `LocalEmotionCheckInRepository(store)` tanto en `app_environment_io.dart:69-70` como en `app_environment_web.dart:61`, y no existe ninguna clase `SupabaseEmotionCheckInRepository` en `packages/data/lib/src/supabase_repositories.dart` | Nadie fuera del dispositivo | Sí — **es el dato más sensible del producto y hoy nunca sale del teléfono** |
| Favoritos de historias/biblioteca | Solo el dispositivo — mismo patrón que arriba: `storyProgressRepositoryProvider` es incondicionalmente `LocalStoryProgressRepository(store)` (`app_environment_io.dart:74-75`), y no existe `SupabaseStoryProgressRepository` | Nadie fuera del dispositivo | Sí |
| Preferencia de notificación por perfil (intensidad, permiso) | Solo el dispositivo — `notificationPreferenceRepositoryProvider` incondicional a `LocalNotificationPreferenceRepository` (`app_environment_io.dart:66-67`) | Nadie fuera del dispositivo | Sí (es de la experiencia del menor, la fija el adulto) |

### Tablas que existen en el esquema pero que la app no usa hoy

Verificado por ausencia total de repositorio o de llamador:

- **`habit_activations`** (`0001_initial_schema.sql:96-106`): no tiene ninguna clase de repositorio en
  `packages/data/lib/src/`, ni se instancia `HabitActivation(...)` en ningún lugar fuera de su propia
  definición en `packages/domain/lib/src/entities.dart`. No se escribe nunca.
- **`audit_logs`** (`0001_initial_schema.sql:177-188`): mismo caso — cero referencias fuera de la definición
  del dominio. No se escribe nunca.
- **`habit_progress`**: sí tiene repositorio (`SupabaseHabitProgressRepository`,
  `packages/data/lib/src/supabase_repositories.dart:1067`), pero ninguna pantalla de
  `apps/mobile/lib/src/features/` construye un `HabitProgress(...)` para guardarlo. La capacidad existe en la
  capa de datos, pero no hay ningún flujo de usuario que la dispare hoy.

Si el cuestionario de Play pregunta por categorías de datos "recolectados", estas tres no deberían marcarse
como recolectadas — no hay código que las escriba, aunque la tabla exista.

---

## 2. Qué se envía a terceros

Dependencias externas revisadas en `apps/mobile/pubspec.yaml` y en el `pubspec.yaml` de cada paquete interno
bajo `packages/*/`. Ningún paquete de analítica, publicidad ni crash-reporting está declarado en ninguno de
los 12 `pubspec.yaml` del repositorio.

| Paquete | Qué hace | Sale algo del dispositivo? | Hacia dónde |
|---|---|---|---|
| `supabase_flutter ^2.16.0` | Autenticación, base de datos, RPCs | **Sí** — todo lo descripto en la Parte 1 que tiene repositorio Supabase | `https://frmgwpbstezqjwbcshbw.supabase.co` (proyecto Supabase de Habitar, ver Parte 3 para la región) |
| `flutter_local_notifications ^17.2.4` | Programa recordatorios de rutina como notificaciones locales del sistema operativo | No — sin llamadas de red en `apps/mobile/lib/src/platform/native_reminder_scheduler.dart` (verificado, sin `http`/`Uri`) | — |
| `share_plus ^10.1.4` / `printing ^5.14.2` / `pdf ^3.11.3` | Generan el PDF de reporte semanal y lo entregan al selector de "compartir" del sistema operativo (`portal_screens.dart:662-669`, `_shareReport`) | Solo si el adulto elige explícitamente compartir o imprimir — en ese momento el PDF (que incluye nombre del perfil y sus estadísticas) sale hacia la app que el adulto elija en el selector del sistema (WhatsApp, correo, Drive, impresora, etc.). No hay ningún envío automático. | Lo que el adulto elija en ese momento — fuera del control de Habitar |
| `path_provider ^2.1.5` | Resuelve la carpeta local donde vive `habitar.sqlite` | No | — |
| `sqlite3_flutter_libs`, `drift`, `sqlite3` | Motor de base de datos local | No | — |
| `go_router`, `flutter_riverpod` | Navegación y estado en memoria | No | — |
| `timezone ^0.9.4` | Cálculo de horarios locales para las rutinas, usa datos de zona horaria embebidos | No | — |
| `web ^1.1.1` | Bindings de JS para la build web | No por sí mismo | — |

### Analítica

**No hay ninguna.** Existe un paquete `habitar_analytics_core` (`packages/analytics_core/lib/analytics_core.dart`)
con una interfaz `AnalyticsSink` y una clase `PrivacySafeEvent` — pero es solo una interfaz, sin ninguna
implementación en todo el repositorio, y **nada la llama**: busqué `AnalyticsSink`/`PrivacySafeEvent`/
`analytics_core` en todo el árbol y las únicas apariciones son su propia definición y su registro como
paquete del workspace en el `pubspec.yaml` raíz. No se envía ningún evento a ningún lado.

### Crash reporting

**No hay ninguno.** No hay `sentry`, `firebase_crashlytics` ni ningún equivalente en ningún `pubspec.yaml`. No
hay ningún `FlutterError.onError` ni `runZonedGuarded` personalizado en `apps/mobile/lib` que reenvíe errores
a un servicio externo (busqué ambos patrones, sin resultados). Los únicos crashes reportados son los que
Google Play Console recolecta de forma nativa del sistema operativo — eso es una capa de la plataforma, no
del código de la app, y no se puede confirmar ni negar desde este repositorio.

### Publicidad

**No hay ninguna.** No hay SDK de anuncios en ningún `pubspec.yaml` (nada de `google_mobile_ads`, AdMob, Meta
Audience Network, etc.), no hay dependencia de Google Play Services de anuncios en
`apps/mobile/android/app/build.gradle.kts` (revisado completo, solo declara `desugar_jdk_libs`), y el
manifest fusionado (ver Parte 4) no incluye `com.google.android.gms.permission.AD_ID` — el permiso que Android
13+ exige declarar para acceder al ID de publicidad. Su ausencia confirma que la app no accede a ese
identificador.

### Push notifications de un servidor propio

**No hay.** No hay `firebase_messaging` ni ningún cliente de push en `pubspec.yaml`. Los recordatorios de
rutina son notificaciones **locales**, programadas en el propio dispositivo por `flutter_local_notifications` —
no llegan desde un servidor de Habitar.

### Confirmación explícita

No hay analítica de uso, no hay publicidad, no hay tracking publicitario, no hay crash reporting de terceros.
El único tercero que recibe datos de forma sistemática es **Supabase**, como proveedor de infraestructura
(base de datos + autenticación). El único envío adicional es el que el propio adulto inicia a mano al
compartir o imprimir el reporte PDF.

---

## 3. Dónde se almacena

### En la nube — Supabase

- **Proyecto:** referencia `frmgwpbstezqjwbcshbw`, URL `https://frmgwpbstezqjwbcshbw.supabase.co`
  (`scripts/android_build_release.ps1:53,69`, validado también en tiempo de build).
- **Región del proyecto:** **no se puede determinar desde el código.** No hay ningún `supabase/config.toml`
  en el repositorio (confirmado — no existe), y ningún archivo menciona la región de hosting. Hay que
  verificarlo directamente en el dashboard de Supabase (Project Settings → General → Region) antes de
  completar el formulario de Play, que pregunta específicamente en qué país/región se almacenan los datos.
- **Qué guarda:** todas las tablas de la Parte 1 marcadas con repositorio Supabase — esencialmente todo lo que
  no está explícitamente marcado como "solo el dispositivo".
- **Motor:** Postgres estándar de Supabase, con Row Level Security en todas las tablas (`alter table ...
  enable row level security` aparece en cada migración que crea una tabla nueva). El acceso desde la app usa
  **solo** REST (PostgREST, vía `.from('tabla')`) y funciones RPC `SECURITY DEFINER` — no encontré uso de
  Supabase Storage (`.storage.`, sin resultados), ni de Supabase Realtime (`.channel(`, sin resultados), ni de
  Edge Functions invocadas desde el cliente (`.functions.invoke`, sin resultados). No se suben archivos ni
  fotos a ningún bucket.

### En el dispositivo

- **Base de datos local (SQLite vía Drift):** en Android/iOS, `getApplicationSupportDirectory()/habitar.sqlite`
  (`apps/mobile/lib/src/app_environment_io.dart:15-17`). **Se crea siempre**, incluso cuando la app está
  configurada contra Supabase — ahí viven las colecciones que nunca van a la nube: `notification_preferences`,
  `emotion_check_ins`, `story_progress`, `adult_profiles`, más una cola de sincronización (`sync_queue`) que
  existe en el esquema pero no tiene ningún lector en `apps/mobile/lib/src/features/` (no se usa hoy). Lista
  completa de colecciones locales en `packages/data/lib/src/local_store.dart:11-35`.
- **Web:** `BrowserLocalStore` guarda todo en `window.localStorage` del navegador, bajo el prefijo `habitar::`
  (`apps/mobile/lib/src/app_environment_web.dart:80-132`). Nunca sale del navegador salvo lo que ya va a
  Supabase por su propio repositorio.
- **Sesión de autenticación:** `Supabase.initialize` se llama sin ninguna opción de almacenamiento
  personalizada (`app_environment_io.dart:84`, `app_environment_web.dart:76` — ambos pasan solo `url` y
  `publishableKey`). Confirmé en el código fuente del paquete
  (`supabase_flutter-2.16.0/lib/src/local_storage.dart:67-117`) que sin esa opción, `supabase_flutter` usa por
  default `SharedPreferencesLocalStorage`: guarda el token de sesión **en texto plano** dentro de
  `SharedPreferences` de Android (un archivo XML privado de la app) o `localStorage` en web. No se usa
  `flutter_secure_storage` ni ningún cifrado adicional sobre ese token.

### Qué pasa si el usuario desinstala la app

- **Lo local** (`habitar.sqlite`, `SharedPreferences`, incluida la sesión) se borra junto con el
  almacenamiento privado de la app, como en cualquier app de Android — con una salvedad verificable: el
  `<application>` de `apps/mobile/android/app/src/main/AndroidManifest.xml` **no declara
  `android:allowBackup="false"`**, así que hereda el default de Android (`true`). Eso significa que el backup
  automático de Android (a la cuenta de Google del dispositivo) puede incluir los datos de la app — sin una
  regla de backup personalizada que lo excluya, no puedo confirmar desde el código si eso realmente pasa en la
  práctica (depende de la versión de Android y de si el usuario tiene el backup automático activado), pero el
  manifest no lo impide explícitamente.
- **Lo que está en Supabase no se borra al desinstalar.** Vive en la nube, independiente del dispositivo, y
  sigue existiendo hasta que se borre por el proceso descrito en la Parte 5.

---

## 4. Permisos de Android

Leído `apps/mobile/android/app/src/main/AndroidManifest.xml` completo (58 líneas). Declara exactamente tres
permisos:

| Permiso | Para qué se usa (verificado) | ¿Sigue en uso? |
|---|---|---|
| `android.permission.INTERNET` | Requerido por `supabase_flutter` para hablar con Supabase (auth + base de datos) | Sí |
| `android.permission.POST_NOTIFICATIONS` | Requerido por `flutter_local_notifications` para mostrar los recordatorios de rutina en Android 13+ | Sí |
| `android.permission.VIBRATE` | Vibración de los recordatorios (`routines.vibration_enabled`, `supabase/migrations/0002_routine_scheduling.sql:16`) y de las notificaciones locales | Sí |

**No hay ningún permiso de más para retirar.** Los tres se usan y tienen una razón concreta y verificable en
el código.

**Verifiqué también el manifest fusionado**, es decir, qué permisos agregan los plugins de Flutter por su
cuenta (cada plugin trae su propio `AndroidManifest.xml` que Gradle mezcla con el de la app). Revisé el
manifest de cada plugin instalado, en la caché de pub (`C:\Users\eugen\AppData\Local\Pub\Cache\hosted\
pub.dev\`):

- `flutter_local_notifications-17.2.4`: vuelve a declarar `VIBRATE` y `POST_NOTIFICATIONS` (ya estaban).
- `share_plus-10.1.4` y `printing-5.15.0`: no agregan ningún permiso — solo un `FileProvider` no exportado
  para pasarle el PDF al selector de "compartir".
- `supabase_flutter-2.16.0`: vuelve a declarar `INTERNET` (ya estaba).
- `sqlite3_flutter_libs`, `path_provider_android`: no tienen `AndroidManifest.xml` propio, no agregan nada.

**Conclusión verificada, no supuesta:** el manifest final del APK no debería tener más que estos 3 permisos.

**Nota cruzada, no pedida pero relevante:** también miré `apps/mobile/ios/Runner/Info.plist` — no tiene
ninguna clave `*UsageDescription` (cámara, micrófono, ubicación, contactos, etc.), consistente con lo que
muestra el lado Android.

---

## 5. Retención y borrado

**Hoy no existe ninguna forma de que un usuario borre su cuenta o sus datos desde dentro de la app.** Busqué
cualquier pantalla, botón o flujo de "eliminar cuenta" / "borrar cuenta" / "eliminar familia" en todo
`apps/mobile/lib` y no encontré nada — ni en `family_dashboard_screen.dart`, ni en `profiles_screen.dart`, ni
en ningún archivo de `features/`. No hay ninguna función `deleteAccount` ni llamada a
`supabase.auth.admin.deleteUser` (que de todos modos requeriría la `service_role` key, que nunca debe estar en
el cliente).

**Sí existe un proceso de eliminación por fuera de la app:** `sites/habitarpy/account-deletion/index.html`
describe pedirla por correo a `soporte@habitarpy.com` con el asunto "Eliminar cuenta Habitar". Es manual, no
automatizado, y no está enlazado desde ningún lugar de la app misma (revisé, no hay ningún link a esa página
ni a ese proceso dentro de `apps/mobile/lib`).

**Esto probablemente no alcanza para el cuestionario de Play.** El formulario de seguridad de datos de Google
Play pregunta explícitamente si la app permite solicitar la eliminación de la cuenta, y desde 2023 Google
exige que exista **tanto** una vía web **como** una vía dentro de la propia app para iniciar el proceso (no
alcanza con una página externa) cuando la app permite crear una cuenta. Hoy Habitar tiene la vía web pero no
la vía dentro de la app — es algo para construir, no algo que ya esté cubierto. Esto es una observación sobre
lo que falta, no una implementación (según lo pedido, no construí nada acá).

**Qué pasaría técnicamente si se borrara una cuenta**, según las foreign keys de las migraciones (relevante
para diseñar el proceso, aunque hoy no exista):

- La mayoría de las tablas referencian `owner uuid references auth.users(id) on delete cascade` — si se
  borrara la fila de `auth.users` de un adulto, todo lo que tenga a ese adulto como `owner` se borraría en
  cascada automáticamente (`0001_initial_schema.sql`, columna `owner` en cada tabla).
- **Riesgo técnico a tener en cuenta, no verificado como bug pero sí como diseño a revisar:** `owner` se fija
  al adulto que hizo el `insert`, no necesariamente al `owner` de rol `'owner'` de la familia. Si un
  `caregiver` creó una rutina y después se borra la cuenta de ESE `caregiver` (no la del dueño de la
  familia), esa rutina se borraría en cascada aunque el resto de la familia siga usando la cuenta — porque el
  borrado en cascada sigue la columna `owner`, no la pertenencia a la familia. Antes de construir un flujo de
  "borrar mi cuenta", vale la pena decidir si eso es el comportamiento deseado para una familia con varios
  adultos, o si hay que reasignar `owner` antes de borrar.
- Algunas columnas usan `on delete set null` en vez de cascada — por ejemplo
  `time_bank_benefits.approved_by_adult_id`, `routine_overrides.created_by`,
  `family_activity_events.created_by`, y `routine_sessions`/`routines` en `time_bank_benefits` cuando se
  archivan (no se borran) — esas filas sobreviven a la baja del adulto, solo pierden la referencia a quién
  hizo la acción.
- Ninguna migración tiene un `on delete cascade` que borre la **familia entera** cuando se borra un adulto
  puntual — `families.owner references auth.users(id) on delete cascade` sí borraría la familia completa si
  se borra específicamente la cuenta del `auth.users` que figura como dueño original de esa fila `families`
  (no de cualquier miembro).

**No hay ninguna política de retención automática por tiempo** (nada de "borrar después de X días") en
ninguna migración — los datos quedan indefinidamente hasta un borrado manual (por soporte, hoy) o hasta que se
construya un proceso automatizado.

---

## 6. Lo que NO recolectamos

Confirmado por ausencia verificable de permisos, paquetes y código — no una lista de intenciones:

- **Ubicación:** no hay `ACCESS_FINE_LOCATION` ni `ACCESS_COARSE_LOCATION` en el manifest, no hay
  `geolocator`, `location` ni ningún paquete de mapas/GPS en ningún `pubspec.yaml` del repositorio.
- **Contactos:** no hay `READ_CONTACTS` en el manifest, no hay `contacts_service` ni equivalente en ningún
  `pubspec.yaml`.
- **Cámara:** no hay `CAMERA` en el manifest, no hay `camera`, `image_picker` ni ningún paquete que abra la
  cámara. `HabitarAvatar` (`packages/design_system/lib/design_system.dart:834-868`) usa solo la inicial del
  nombre sobre un color — no hay fotos de perfil en ningún lado del producto hoy.
- **Micrófono:** no hay `RECORD_AUDIO` en el manifest, no hay ningún paquete de grabación o reconocimiento de
  voz.
- **Tracking publicitario:** sin SDK de ads, sin `AD_ID` permission (ver Parte 2 y 4) — no hay ningún
  identificador publicitario al que la app acceda.

Estas cinco ausencias están respaldadas por: (a) el manifest completo leído en la Parte 4, incluido el
manifest fusionado con lo que aportan los plugins, y (b) el listado completo de dependencias en los 12
`pubspec.yaml` del repositorio (`apps/mobile` + 11 paquetes bajo `packages/`), ninguno de los cuales declara
un paquete de cámara, ubicación, contactos, audio o publicidad.

---

## Resumen para quien complete el formulario de Play

- **Se comparte con un tercero:** sí, con Supabase, como procesador de infraestructura (auth + base de datos).
  Ningún otro tercero recibe datos automáticamente.
- **Se comparte con la aplicación de compartir del usuario:** solo si el adulto lo pide explícitamente
  (reporte PDF), nunca automático.
- **Analítica / publicidad / tracking:** ninguno, en ningún caso.
- **Datos de menores:** sí se recolectan (nombre/apodo, edad, rutinas, horarios, progreso e historial de
  actividad) — visibles para cualquier adulto de la familia, sin importar su rol. El dato más sensible
  (check-ins emocionales) nunca sale del dispositivo hoy.
- **Cifrado en tránsito:** Supabase usa HTTPS por default (la URL se valida como `https://` en
  `scripts/android_build_release.ps1:98-99`); no verifiqué configuración de TLS a nivel de Supabase, es
  configuración de plataforma no de este repositorio.
- **Eliminación de cuenta:** vía web (correo), no vía app — probablemente insuficiente para los requisitos
  actuales de Play si la app permite crear cuenta, como es el caso.
