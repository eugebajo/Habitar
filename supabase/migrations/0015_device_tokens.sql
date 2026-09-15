-- Etapa 3 del rediseño: notificaciones push entre dispositivos. Esta
-- migracion es puramente aditiva - dos tablas nuevas, tres columnas nuevas
-- en family_activity_events, tres funciones nuevas - y no borra ni
-- transforma ningun dato existente. Segura de aplicar en cualquier
-- momento: hasta que exista una Edge Function desplegada que efectivamente
-- llame a claim_pending_routine_notifications, el unico efecto observable
-- es que family_activity_events acumula filas con notified_at en null -
-- nunca una falla ni una demora de complete_routine_session, que esta
-- migracion no toca en absoluto.
--
-- POR QUE POLLING Y NO UN TRIGGER (version anterior de este archivo)
--
-- La primera version de esta migracion usaba un trigger AFTER INSERT sobre
-- family_activity_events que llamaba a la Edge Function via pg_net.http_post,
-- autenticado con la service_role key guardada en Supabase Vault. Descartada
-- a proposito, con esta razon explicita: cada secreto que vive dentro de la
-- base es una superficie de ataque permanente si alguien alguna vez logra
-- ejecutar SQL arbitrario ahi (via el rol con el que se corren migraciones,
-- que en un proyecto Supabase tiene acceso de lectura a Vault) - y esta app
-- maneja datos de menores. Una superficie que no existe no se puede atacar,
-- y vale mas que el minuto de latencia que cuesta no tenerla.
--
-- Este archivo no tiene ninguna extension de red (ni pg_net, ni http),
-- ningun trigger, y ningun secreto guardado en la base. Lo unico que agrega
-- es estado plano (columnas, indices) y dos funciones SECURITY DEFINER que
-- leen y actualizan ese estado - nada con capacidad de iniciar una conexion
-- de red. La Edge Function (parte 2) es quien inicia todo, llamando a estas
-- funciones por su cuenta en una corrida programada por FUERA de Supabase
-- (ver el mensaje que acompaña esta migracion para el analisis completo de
-- Cron nativo de Supabase - que si requiere pg_net - contra un disparador
-- externo, que no requiere nada adentro de la base).
--
-- Beneficio adicional de este diseño, no solo ausencia de riesgo: un envio
-- que falla se puede reintentar en la proxima corrida (ver
-- notification_attempts mas abajo). Con el trigger anterior, un POST
-- fallido (Edge Function caida, timeout) se perdia para siempre - no habia
-- ningun mecanismo de reintento, pg_net solo deja un log de la falla.
--
-- QUE AGREGA
--
-- 1. public.device_tokens - sin cambios respecto a la version anterior de
--    este archivo. Un token de FCM por fila, no por usuario: un mismo
--    adulto puede tener mas de un dispositivo (su telefono personal y, en
--    el modelo de dispositivo compartido, el dispositivo que el chico usa
--    mientras esta logueado con la cuenta de ese adulto) y ambos tienen
--    que poder recibir avisos de forma independiente. Por eso la clave
--    unica es `token` solo, nunca `(user_id, platform)` - esa combinacion
--    pisaria el token de un dispositivo cada vez que el otro se registre.
--
-- 2. public.notification_preferences_by_user - sin cambios. Deliberadamente
--    un nombre distinto a la tabla `notification_preferences` que ya
--    existe desde 0001_initial_schema.sql y que es la intensidad de aviso
--    LOCAL de un PERFIL DE CHICO (verificado antes de crear esta tabla) -
--    un concepto completamente distinto a "este adulto quiere recibir
--    avisos push de actividad familiar".
--
-- 3. Tres columnas nuevas en family_activity_events (unica tabla que se
--    altera, y solo con columnas nuevas - ningun dato existente cambia):
--      notified_at            timestamptz, null hasta que se entregue
--      notification_attempts  int, cuantas veces se intento (exitosa o no)
--      notification_last_error text, motivo del ultimo fallo, sin tokens
--    Se eligio extender esta tabla en vez de una cola de entrega aparte:
--    hoy hay un solo tipo de evento y un solo consumidor, asi que una cola
--    separada resolveria un problema que todavia no existe. Si en el
--    futuro aparece un segundo tipo de evento que necesite push, migrar a
--    una cola en ese momento es un cambio chico y acotado.
--
-- 4. public.claim_pending_routine_notifications(p_max_events) - la Edge
--    Function la llama en cada corrida programada. Selecciona hasta
--    p_max_events eventos 'routine_completed' con notified_at null,
--    menos de 5 intentos previos, y de menos de 6 horas de antiguedad;
--    incrementa notification_attempts de cada uno ATOMICAMENTE al
--    reclamarlos (for update skip locked, para que dos corridas
--    superpuestas nunca reclamen el mismo evento dos veces) y devuelve
--    sus datos ya resueltos (profile_display_name, routine_title, etc,
--    que family_activity_events ya trae). El incremento ocurre AL
--    RECLAMAR, no solo si el envio falla despues - asi, si la Edge
--    Function se cae a mitad de un envio y nunca vuelve a llamar a
--    mark_routine_notification_sent, ese evento igual no queda
--    reclamable para siempre.
--
-- 5. public.mark_routine_notification_sent(event_id) - la Edge Function la
--    llama por cada evento que efectivamente termino de procesar (envio
--    exitoso, o resuelto sin destinatarios - las dos cosas cuentan como
--    "hecho", no solo un push realmente entregado). No hace falta una
--    funcion separada para marcar fallos: si un intento falla, simplemente
--    no se llama a esta funcion, y el evento sigue candidato en la
--    proxima corrida hasta agotar los 5 intentos o las 6 horas.
--
-- 6. public.resolve_routine_notification_recipients(event_id) - SIN
--    CAMBIOS respecto a la version anterior de este archivo, copiada tal
--    cual. Dado un family_activity_event, devuelve los (user_id, token,
--    platform) que tienen que recibirlo: solo adultos de la misma
--    familia, nunca quien lo origino (created_by, con IS DISTINCT FROM
--    para tratar un created_by null como "no excluir a nadie" en vez de
--    "no encontrar match con nadie"), respetando push_enabled y el
--    horario silencioso en America/Asuncion (con el caso de rango que
--    cruza medianoche resuelto aparte del caso normal). SECURITY DEFINER
--    porque necesita leer device_tokens de otros usuarios - la funcion
--    misma es el limite de seguridad, por eso su EXECUTE esta revocado a
--    todos salvo service_role.
--
-- QUE NO HACE ESTA MIGRACION: no despliega la Edge Function (parte 2), no
-- programa ninguna corrida (eso vive fuera de Supabase - ver el mensaje
-- que acompaña esta migracion), no carga ningun secreto, no cambia
-- complete_routine_session.
--
-- ROLLBACK (manual, aditivo puro - no borra ni transforma ningun dato
-- existente al revertir; las columnas nuevas en family_activity_events
-- se pueden dropear sin perder ninguna de sus columnas originales):
--   drop function if exists public.mark_routine_notification_sent(uuid);
--   drop function if exists
--     public.claim_pending_routine_notifications(int);
--   drop function if exists
--     public.resolve_routine_notification_recipients(uuid);
--   drop index if exists public.family_activity_events_pending_notification_idx;
--   alter table public.family_activity_events
--     drop column if exists notified_at,
--     drop column if exists notification_attempts,
--     drop column if exists notification_last_error;
--   drop table if exists public.notification_preferences_by_user;
--   drop table if exists public.device_tokens;

-- ---------------------------------------------------------------------------
-- 1. device_tokens
-- ---------------------------------------------------------------------------

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (token)
);

comment on table public.device_tokens is
  'Un token de FCM por fila, no por usuario - un adulto puede tener mas '
  'de un dispositivo registrado a la vez. unique(token) solo, nunca '
  '(user_id, platform): esa combinacion pisaria el token de un '
  'dispositivo cada vez que otro se registre. Tokens rotados/invalidos '
  'se limpian en el momento de mandar (ver README de la Edge Function), '
  'no aca.';

alter table public.device_tokens enable row level security;

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

drop policy if exists "adults manage their own device tokens"
  on public.device_tokens;
create policy "adults manage their own device tokens"
on public.device_tokens for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- Sin acceso para anon. authenticated queda acotado a sus propias filas
-- por la policy de arriba (aplica a select/insert/update/delete por
-- igual, "for all"); revoke explicito primero porque Supabase da grants
-- de tabla por default a public/authenticated en el schema public al
-- crear una tabla nueva - mismo patron que
-- 0011_family_activity_events.sql:84-87 y
-- 0014_family_deletion.sql:152-154, no asumir privilegios por default.
revoke all on public.device_tokens from anon;
revoke all on public.device_tokens from authenticated;
grant select, insert, update, delete on public.device_tokens to authenticated;

-- ---------------------------------------------------------------------------
-- 2. notification_preferences_by_user
-- ---------------------------------------------------------------------------

create table if not exists public.notification_preferences_by_user (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  quiet_hours_start time,
  quiet_hours_end time,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id),
  -- Los dos limites del horario silencioso van juntos o no van - evita
  -- una fila con "empieza a las 21:00" y ningun fin nunca configurado.
  constraint notification_preferences_quiet_hours_pair check (
    (quiet_hours_start is null) = (quiet_hours_end is null)
  )
);

comment on table public.notification_preferences_by_user is
  'Preferencias de notificacion push POR ADULTO (auth.users). No '
  'confundir con public.notification_preferences (desde 0001), que es '
  'la intensidad de aviso LOCAL de un perfil de chico - conceptos '
  'distintos, verificado antes de crear esta tabla.';

alter table public.notification_preferences_by_user enable row level security;

drop policy if exists "adults manage their own notification preferences"
  on public.notification_preferences_by_user;
create policy "adults manage their own notification preferences"
on public.notification_preferences_by_user for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

revoke all on public.notification_preferences_by_user from anon;
revoke all on public.notification_preferences_by_user from authenticated;
grant select, insert, update, delete
  on public.notification_preferences_by_user to authenticated;

-- ---------------------------------------------------------------------------
-- 3. family_activity_events: columnas de estado de entrega
-- ---------------------------------------------------------------------------

alter table public.family_activity_events
  add column if not exists notified_at timestamptz,
  add column if not exists notification_attempts int not null default 0,
  add column if not exists notification_last_error text;

comment on column public.family_activity_events.notified_at is
  'Null hasta que la Edge Function confirma que termino de procesar este '
  'evento (envio exitoso, o resuelto sin destinatarios - las dos cuentan '
  'como "hecho"). Un evento que agoto sus reintentos o su ventana de edad '
  '(ver claim_pending_routine_notifications) queda con esto en null para '
  'siempre - eso es intencional, no hace falta un estado "abandonado" '
  'aparte.';

comment on column public.family_activity_events.notification_attempts is
  'Se incrementa al RECLAMAR el evento (claim_pending_routine_notifications), '
  'no solo cuando el envio falla - asi un crash de la Edge Function a '
  'mitad de un envio no deja el evento reclamable para siempre. Tope de '
  '5 intentos, ver esa funcion.';

comment on column public.family_activity_events.notification_last_error is
  'Motivo del ultimo intento fallido, para diagnostico. Quien la escriba '
  '(Edge Function) nunca debe volcar aca un token de device_tokens ni '
  'ningun otro dato personal - solo el tipo de error (timeout, FCM '
  'rechazado, etc).';

-- Indice parcial: solo indexa lo que todavia falta mandar. Se achica solo
-- a medida que notified_at deja de ser null en cada fila - nunca hace
-- falta mantenimiento aparte.
create index if not exists family_activity_events_pending_notification_idx
  on public.family_activity_events (created_at)
  where kind = 'routine_completed' and notified_at is null;

-- ---------------------------------------------------------------------------
-- 4. claim_pending_routine_notifications
-- ---------------------------------------------------------------------------

create or replace function public.claim_pending_routine_notifications(
  p_max_events int default 50
)
returns table (
  event_id uuid,
  family_id uuid,
  profile_display_name text,
  routine_title text,
  routine_id uuid,
  profile_id uuid,
  created_by uuid,
  notification_attempts int
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  return query
  with pending as (
    select fae.id
    from public.family_activity_events as fae
    where fae.kind = 'routine_completed'
      and fae.notified_at is null
      -- Tope de intentos: 5. Una Edge Function que sigue fallando despues
      -- de 5 corridas no va a empezar a funcionar en la sexta - a partir
      -- de aca, el evento deja de ser candidato (ver comentario en
      -- notified_at sobre por que no hace falta un estado aparte).
      and fae.notification_attempts < 5
      -- Tope de edad: 6 horas. Un aviso de "termino su rutina" de hace 6
      -- horas ya no cumple el proposito de la funcionalidad (que el otro
      -- adulto se entere mientras todavia es relevante) - mas alla de
      -- este punto, no vale la pena seguir intentando aunque queden
      -- intentos disponibles.
      and fae.created_at > now() - interval '6 hours'
    order by fae.created_at
    limit p_max_events
    -- skip locked: si dos corridas de la Edge Function se superponen
    -- (la anterior todavia no termino cuando arranca la siguiente), cada
    -- una reclama filas distintas en vez de mandar el mismo aviso dos
    -- veces.
    for update of fae skip locked
  )
  update public.family_activity_events as fae
  set notification_attempts = fae.notification_attempts + 1
  from pending
  where fae.id = pending.id
  returning
    fae.id as event_id,
    fae.family_id,
    fae.profile_display_name,
    fae.routine_title,
    fae.routine_id,
    fae.profile_id,
    fae.created_by,
    fae.notification_attempts;
end;
$$;

comment on function public.claim_pending_routine_notifications(int) is
  'Reclama hasta p_max_events eventos routine_completed pendientes de '
  'aviso (incrementando notification_attempts atomicamente al '
  'reclamarlos) y devuelve sus datos ya resueltos. Llamada solo por la '
  'Edge Function en su corrida programada - EXECUTE revocado a todos '
  'salvo service_role.';

revoke all on function public.claim_pending_routine_notifications(int)
  from public, anon, authenticated;
grant execute on function public.claim_pending_routine_notifications(int)
  to service_role;

-- ---------------------------------------------------------------------------
-- 5. mark_routine_notification_sent
-- ---------------------------------------------------------------------------

create or replace function public.mark_routine_notification_sent(
  p_event_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.family_activity_events
  set notified_at = now()
  where id = p_event_id;
end;
$$;

comment on function public.mark_routine_notification_sent(uuid) is
  'Marca un evento como procesado (enviado, o resuelto sin '
  'destinatarios). Sin funcion equivalente para marcar fallos a '
  'proposito: si un intento falla, simplemente no se llama a esta '
  'funcion y el evento sigue candidato en la proxima corrida. EXECUTE '
  'revocado a todos salvo service_role.';

revoke all on function public.mark_routine_notification_sent(uuid)
  from public, anon, authenticated;
grant execute on function public.mark_routine_notification_sent(uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- 6. resolve_routine_notification_recipients (sin cambios)
-- ---------------------------------------------------------------------------

create or replace function public.resolve_routine_notification_recipients(
  p_event_id uuid
)
returns table (
  recipient_user_id uuid,
  token text,
  platform text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  event_row record;
  current_local_time time;
begin
  select fae.family_id, fae.created_by
  into event_row
  from public.family_activity_events as fae
  where fae.id = p_event_id;

  -- Evento inexistente (borrado, id mal formado, lo que sea): ningun
  -- destinatario, sin lanzar excepcion - quien llama (la Edge Function)
  -- ya maneja una lista vacia sin problema.
  if not found then
    return;
  end if;

  current_local_time := (now() at time zone 'America/Asuncion')::time;

  return query
  select
    fm.user_id as recipient_user_id,
    dt.token,
    dt.platform
  from public.family_members as fm
  join public.device_tokens as dt
    on dt.user_id = fm.user_id
  left join public.notification_preferences_by_user as np
    on np.user_id = fm.user_id
  where fm.family_id = event_row.family_id
    -- is distinct from, no <>: created_by puede ser null (0013 lo deja
    -- en null si el adulto que completo la rutina ya borro su cuenta) -
    -- con <> ningun user_id matchearia nunca contra un created_by null y
    -- la lista de destinatarios quedaria vacia por error. is distinct
    -- from trata null como "no excluir a nadie", que es lo correcto.
    and fm.user_id is distinct from event_row.created_by
    and coalesce(np.push_enabled, true)
    and not (
      np.quiet_hours_start is not null
      and np.quiet_hours_end is not null
      and (
        case
          -- Rango normal, ej. 13:00-14:00 (siesta).
          when np.quiet_hours_start <= np.quiet_hours_end then
            current_local_time >= np.quiet_hours_start
            and current_local_time < np.quiet_hours_end
          -- Rango que cruza medianoche, ej. 22:00-07:00.
          else
            current_local_time >= np.quiet_hours_start
            or current_local_time < np.quiet_hours_end
        end
      )
    );
end;
$$;

comment on function public.resolve_routine_notification_recipients(uuid) is
  'SECURITY DEFINER: necesita leer device_tokens de otros usuarios, algo '
  'que la RLS de esa tabla (cada adulto ve solo lo suyo) no permite por '
  'diseño. La funcion misma es el limite de seguridad - por eso su '
  'EXECUTE esta revocado a todos salvo service_role, nunca a '
  'authenticated: ningun cliente de Flutter puede llamarla para '
  'enumerar tokens ajenos.';

-- Nunca a authenticated ni anon - ver el comentario de arriba. Solo la
-- Edge Function (via service_role) puede resolver destinatarios.
revoke all on function public.resolve_routine_notification_recipients(uuid)
  from public, anon, authenticated;
grant execute on function public.resolve_routine_notification_recipients(uuid)
  to service_role;

-- ---------------------------------------------------------------------------
-- VERIFICACION MANUAL DESPUES DE APLICAR
-- ---------------------------------------------------------------------------
--
-- 1. Estructura:
--   select column_name, is_nullable, column_default
--   from information_schema.columns
--   where table_schema = 'public'
--     and table_name in ('device_tokens', 'notification_preferences_by_user')
--   order by table_name, ordinal_position;
--
--   select column_name, data_type, column_default
--   from information_schema.columns
--   where table_schema = 'public' and table_name = 'family_activity_events'
--     and column_name in ('notified_at', 'notification_attempts', 'notification_last_error');
--   -- notification_attempts debe tener default 0, las otras dos deben
--   -- aceptar null.
--
--   select indexname, indexdef from pg_indexes
--   where schemaname = 'public'
--     and indexname = 'family_activity_events_pending_notification_idx';
--
--   select policyname, cmd, roles from pg_policies
--   where schemaname = 'public'
--     and tablename in ('device_tokens', 'notification_preferences_by_user');
--   -- Debe mostrar exactamente una policy "for all" por tabla, ambas
--   -- "using (user_id = auth.uid())".
--
--   select grantee, privilege_type from information_schema.role_table_grants
--   where table_schema = 'public'
--     and table_name in ('device_tokens', 'notification_preferences_by_user')
--     and grantee in ('anon', 'authenticated');
--   -- anon: ninguno. authenticated: select/insert/update/delete en ambas.
--
--   select p.proname, p.prosecdef from pg_proc p
--   join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname = 'public'
--     and p.proname in ('resolve_routine_notification_recipients',
--                        'claim_pending_routine_notifications',
--                        'mark_routine_notification_sent');
--   -- Las tres con prosecdef = true.
--
--   select routine_name, grantee, privilege_type
--   from information_schema.role_routine_grants
--   where routine_schema = 'public'
--     and routine_name in ('resolve_routine_notification_recipients',
--                           'claim_pending_routine_notifications',
--                           'mark_routine_notification_sent');
--   -- Solo service_role en las tres. Ni anon ni authenticated deben
--   -- aparecer aca - si aparecen, algo salio mal con el revoke de arriba.
--
--   -- Confirmar que NO quedo nada de la version anterior de este archivo
--   -- (trigger, funcion de trigger, extension pg_net) si este archivo se
--   -- esta re-aplicando sobre un intento previo:
--   select count(*) from pg_trigger
--   where tgname = 'family_activity_events_dispatch_notification';
--   -- Debe ser 0. Si no lo es: drop trigger
--   -- family_activity_events_dispatch_notification on
--   -- public.family_activity_events; drop function if exists
--   -- public.dispatch_routine_notification(); antes de re-aplicar.
--
-- 2. Comportamiento (con datos de prueba, en un entorno descartable o
--    con cuentas de prueba - no contra familias reales):
--   - Dos adultos en la misma familia, cada uno con un token en
--     device_tokens. El adulto A completa una rutina (llama
--     complete_routine_session). select * from
--     claim_pending_routine_notifications(10) debe devolver ese evento,
--     con notification_attempts en 1 despues de la llamada (no 0).
--     select * from resolve_routine_notification_recipients(<ese
--     event_id>) debe devolver el token del adulto B, nunca el de A.
--   - Un tercer adulto en OTRA familia, con token propio: no debe
--     aparecer nunca en el resultado de resolve_routine_notification_recipients
--     de arriba.
--   - Llamar a claim_pending_routine_notifications(10) una segunda vez
--     sin haber llamado a mark_routine_notification_sent: el mismo
--     evento vuelve a aparecer (notified_at sigue null), con
--     notification_attempts ahora en 2.
--   - Llamar a mark_routine_notification_sent(<event_id>) y despues a
--     claim_pending_routine_notifications(10) de nuevo: ese evento ya no
--     aparece.
--   - Insertar (o simular) un evento con notification_attempts = 5:
--     claim_pending_routine_notifications no debe devolverlo.
--   - Insertar (o simular) un evento con created_at de hace 7 horas:
--     claim_pending_routine_notifications no debe devolverlo, sin
--     importar notification_attempts.
--   - Poner push_enabled = false para el adulto B: el resultado de
--     resolve_routine_notification_recipients pasa a estar vacio.
--   - Poner quiet_hours_start/end de forma que la hora actual en
--     America/Asuncion caiga adentro (probar un rango normal y uno que
--     cruce medianoche): el resultado queda vacio mientras dure la
--     ventana, y vuelve a aparecer fuera de ella.
--   - Dos llamadas concurrentes a claim_pending_routine_notifications
--     (dos conexiones distintas, mismo momento) con un solo evento
--     pendiente: exactamente una de las dos debe devolverlo, la otra
--     una lista vacia - confirma que el "for update skip locked" evita
--     el doble aviso.
