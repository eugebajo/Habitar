# send-routine-notification

Edge Function de la etapa 3 (notificaciones push entre dispositivos). No está
desplegada todavía - este documento son los pasos exactos para hacerlo.

## Qué hace, en una frase

Cada vez que se la invoca, reclama hasta 50 eventos `routine_completed`
pendientes de aviso (`claim_pending_routine_notifications`), resuelve a quién
avisar por cada uno (`resolve_routine_notification_recipients`) y les manda un
push por FCM HTTP v1. Ver los comentarios al principio de `index.ts` para el
detalle completo, incluido por qué el disparo es un cron externo (GitHub
Actions) y no un trigger de base de datos.

## Qué NO hace este documento

No despliega la función (`supabase functions deploy` lo hacés vos, paso 2 de
abajo). No carga ningún secreto (paso 3). No aplica la migración `0015` - ya
la aplicaste vos antes de esto.

## 1. Prerrequisito: confirmar que 0015 ya está aplicada

Si no lo confirmaste todavía en este mismo entorno:

```sql
select p.proname from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('claim_pending_routine_notifications',
                     'mark_routine_notification_sent',
                     'resolve_routine_notification_recipients');
```

Debe devolver las tres filas. Si falta alguna, esta función va a fallar en
cada corrida (con un error claro en los logs, nunca en silencio) hasta que la
apliques.

## 2. Desplegar la función

Desde la raíz del repo, con el Supabase CLI ya autenticado y el proyecto
vinculado (el mismo `frmgwpbstezqjwbcshbw` de siempre):

```bash
supabase functions deploy send-routine-notification
```

Sin `--no-verify-jwt`: la función exige un JWT válido en el header
`Authorization` de cada request - ver el paso 4 (GitHub Actions) para cuál
usar. Esto es a propósito: sin verificación, cualquiera con la URL podría
disparar corridas fuera de horario.

## 3. Cargar el secreto de Firebase

Esta función necesita **una sola** variable de entorno que vos cargás a mano
- `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` las inyecta Supabase solo en
toda Edge Function, no hace falta declararlas.

**`FIREBASE_SERVICE_ACCOUNT_JSON`** - el JSON completo de una cuenta de
servicio de Firebase con permiso de Firebase Cloud Messaging, como un único
string.

Cómo conseguirlo (proyecto **Habitarpy**, el que ya creaste):

1. Firebase Console → ⚙️ (ícono de configuración) → **Configuración del
   proyecto** → pestaña **Cuentas de servicio**.
2. **Generar nueva clave privada** → confirmar → se descarga un `.json`.
   **Este archivo nunca va al repositorio** - es exactamente la clave que
   mencionaste que ya tenés guardada fuera del repo.
3. Cargarlo como secreto de la función (no de la base - esto es distinto de
   Vault, es el mecanismo de secretos propio de Edge Functions):

   ```bash
   supabase secrets set --env-file <(echo "FIREBASE_SERVICE_ACCOUNT_JSON=$(cat ruta/al/archivo-descargado.json | tr -d '\n')")
   ```

   O, más simple, pegando el JSON directo (una sola línea, sin saltos de
   línea reales adentro de las comillas):

   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"habitarpy-9f147",...}'
   ```

   O desde el dashboard: **Edge Functions** → `send-routine-notification` →
   **Secrets** → pegar el JSON completo con el nombre
   `FIREBASE_SERVICE_ACCOUNT_JSON`.

4. Confirmar que quedó cargado:

   ```bash
   supabase secrets list
   ```

   Debe aparecer `FIREBASE_SERVICE_ACCOUNT_JSON` en la lista (el valor no se
   muestra, solo el nombre).

## 4. Probar la función manualmente (antes de programar el cron)

Con el **anon key** del proyecto (Settings → API → `anon` `public`):

```bash
curl -i -X POST \
  'https://frmgwpbstezqjwbcshbw.supabase.co/functions/v1/send-routine-notification' \
  -H "Authorization: Bearer <ANON_KEY>"
```

Con la migración aplicada, el secreto cargado, y sin ningún evento
pendiente todavía, la respuesta esperada es:

```json
{"processed":0,"sent":0}
```

con status `200`. Eso ya confirma que la función arrancó, pudo leer el
secreto de Firebase, y pudo llamar a `claim_pending_routine_notifications`
sin error - aunque todavía no haya mandado ningún push real.

Para probar el envío real de punta a punta, ver el paso 7 de más abajo (dos
teléfonos).

## 5. Programar la corrida cada 5 minutos (GitHub Actions)

El disparo de esta función es un cron externo, no un trigger de la base -
ver el porqué en el encabezado de `index.ts` y de la migración `0015`. Ya
está el workflow en
[`.github/workflows/send-routine-notifications.yml`](../../../.github/workflows/send-routine-notifications.yml),
solo falta cargarle un secreto.

**Un solo secreto, y va en GitHub, no en Supabase:** `SUPABASE_ANON_KEY` -
la clave pública (`anon` `public`) del proyecto, la misma que ya usa la app
Flutter. No es la `service_role` ni la clave de Firebase - esas dos nunca
salen de Supabase. Esta clave solo sirve para pasar la verificación de JWT
que exige la función (recordá que se desplegó sin `--no-verify-jwt`); no da
acceso a nada que la propia función no controle ya con `service_role` del
lado de adentro.

Para cargarla:

1. En GitHub: el repositorio → **Settings** → **Secrets and variables** →
   **Actions** → pestaña **Secrets** → **New repository secret**.
2. Nombre: `SUPABASE_ANON_KEY` (tiene que ser exactamente ese - el workflow
   lo busca por ese nombre).
3. Valor: la clave `anon` `public` del proyecto (Supabase Dashboard →
   Settings → API → `Project API keys` → `anon` `public`).
4. Guardar.

Con eso el workflow ya corre solo cada 5 minutos. Para confirmarlo sin
esperar: pestaña **Actions** del repositorio → **Enviar notificaciones de
rutinas completadas** → **Run workflow**. El log de esa corrida muestra el
`status` HTTP y el cuerpo de la respuesta (`{"processed":N,"sent":M}`) -
nunca un token ni un dato personal, porque la función misma nunca los
imprime (ver el comentario correspondiente en `index.ts`).

Si el secreto falta o está vacío, el workflow falla de entrada con un
mensaje explícito en el log, antes de intentar el `curl` - no hace falta
adivinar por qué falló.

## 6. Revisar los logs

Dashboard → Edge Functions → `send-routine-notification` → **Logs**. Cada
corrida imprime cuántos eventos reclamó, procesó y mandó. Los fallos se
registran con el `event_id` y el tipo de error - nunca con el token ni con
ningún dato personal (ver el comentario correspondiente en `index.ts`).

## 7. Probar que llega una notificación real entre dos teléfonos

Requiere la Parte 3 (Flutter) ya instalada en los dos dispositivos, con
Firebase configurado.

1. Dos cuentas de adulto en la **misma familia**, cada una logueada en su
   propio teléfono (no el mismo teléfono con dos perfiles).
2. En **Cuenta → Notificaciones** de los dos, confirmar "Recibir avisos"
   activado y sin horario silencioso que esté corriendo justo en ese
   momento.
3. En el teléfono A, completar los pasos de una rutina de un perfil de
   chico hasta el final (o usar el botón "Recordar" de una rutina para
   generar actividad, si preferís no completar una real).
4. Esperar hasta 5 minutos (el intervalo del cron de GitHub Actions - ver
   `.github/workflows/send-routine-notifications.yml`) o disparar la
   corrida a mano desde GitHub: pestaña **Actions** → el workflow → **Run
   workflow**.
5. El teléfono B (el que no completó la rutina) debería recibir la
   notificación del sistema - "¡Rutina completada! 🎉" / "<Nombre> terminó
   '<Rutina>'." - aunque Habitar esté cerrada del todo en ese teléfono.
6. Tocar la notificación: Habitar se abre (o pasa a primer plano) y navega
   al Inicio del adulto, donde Actividad reciente ya muestra ese mismo
   evento.
7. Repetir con la app de B en primer plano en el momento del envío: en vez
   de la notificación del sistema, debería aparecer como notificación
   local dentro de la misma sesión (mismo texto).

Si no llega nada, revisar en este orden: los logs de la función (paso 6,
¿la corrida encontró el evento y lo intentó mandar?), la tabla
`device_tokens` (¿el teléfono B tiene un token registrado? - visitar
Familia o crear una rutina en B primero, si nunca se le pidió el permiso),
y por último los permisos de notificación del sistema operativo en el
teléfono B.
