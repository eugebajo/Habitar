-- Etapa 1 de 3 del borrado de cuenta in-app (ver docs/inventario-datos.md, Parte 5,
-- y la conversacion de diseno que la precede). Esta etapa es puramente aditiva:
-- solo cambia que pasa con una fila cuando el auth.users al que apunta desaparece.
-- No borra datos, no cambia ninguna policy de RLS, no agrega tablas ni funciones.
-- Las etapas 2 (funciones: delete_family, transfer_family_ownership,
-- delete_my_account, la tabla de aviso "tu familia fue eliminada", y la purga a
-- los 30 dias) y 3 (interfaz) van en migraciones/commits separados, a pedido
-- explicito: aplicar y verificar de a una.
--
-- ORDEN DE DESPLIEGUE - NO APLICAR TODAVIA EN PRODUCCION:
--
-- Esta migracion vuelve mucho mas facil de disparar un bug preexistente en
-- SupabaseRoutineSessionRepository.completeSession: su update() de
-- routine_sessions no reescribia `owner`, asi que una sesion cuyo `owner` ya
-- no coincide con quien la completa (hoy, un caso raro; con owner en NULL
-- despues de esta migracion, el caso normal para cualquier sesion tocada por
-- un adulto que ya se fue) quedaba rechazada para siempre por el `with check
-- (owner = auth.uid() ...)` de 0007/0012. Ya esta arreglado en
-- packages/data/lib/src/supabase_repositories.dart (completeSession ahora
-- reescribe `owner` en cada guardado, con test de regresion en
-- supabase_routine_completion_test.dart) - pero el arreglo vive en la app,
-- no en la base. **No aplicar esta migracion en el proyecto de produccion de
-- Supabase hasta que la version de Flutter con ese arreglo este publicada e
-- instalada en los telefonos** - misma logica de secuencia que ya aplica
-- 0012_routine_sessions_completion_lockdown.sql. Hoy no hay ninguna urgencia
-- real para aplicarla (el borrado de cuenta que la motiva todavia no existe
-- en la app), asi que no hay apuro en violar este orden.
--
-- EL PROBLEMA QUE RESUELVE
--
-- En el esquema original (0001_initial_schema.sql) toda tabla familiar tiene una
-- columna `owner uuid not null references auth.users(id) on delete cascade` -
-- "quien creo esta fila". Eso fue razonable mientras el modelo era de un solo
-- usuario por cuenta. Desde que 0004 y 0007 lo convirtieron en un modelo
-- familiar de varios adultos, esa columna quedo desalineada: si HOY se borrara
-- la cuenta de auth.users de un caregiver, toda rutina, sesion, habito o pedido
-- de ayuda que ese caregiver haya creado se borraria en cascada - aunque el
-- resto de la familia lo siga usando a diario y el nino no tenga nada que ver
-- con que ese adulto en particular se haya ido.
--
-- Esta migracion cambia esas 15 columnas (14 tablas) de `on delete cascade` a
-- `on delete set null`: cuando el auth.users desaparece, la fila sobrevive, solo
-- pierde la referencia a quien la creo. El acceso familiar nunca dependio de
-- `owner` para SELECT (las policies de 0004/0007 usan family_members + role),
-- asi que esto no abre ni cierra ninguna visibilidad - solo evita que una baja
-- de cuenta individual se lleve puesto contenido compartido.
--
-- Lo que SI sigue en cascada, sin cambios, a proposito: family_id -> families,
-- profile_id -> profiles, routine_id -> routines, habit_id -> habits, y
-- family_members.user_id -> auth.users. Esas cascadas son la forma correcta de
-- borrar todo lo de una familia cuando corresponde (etapa 2, delete_family) o de
-- quitar a un adulto puntual de una familia (correcto que su fila de
-- family_members desaparezca junto con su cuenta). Esta migracion no las toca.
--
-- QUE SE HACE, POR COLUMNA (15 columnas, 14 tablas; todas del esquema 0001,
-- salvo adult_invitations.invited_by_user_id que es de 0004):
--
--   families.owner                      profiles.owner
--   routines.owner                      routine_steps.owner
--   routine_sessions.owner              habits.owner
--   habit_activations.owner             habit_progress.owner
--   notification_preferences.owner      emotion_check_ins.owner
--   support_requests.owner              story_progress.owner
--   audit_logs.owner                    audit_logs.actor_id
--   adult_invitations.invited_by_user_id
--
-- Para cada una: se descubre el nombre real de su foreign key hacia auth.users
-- consultando pg_constraint (igual que 0010_invitation_codes.sql hizo con el
-- check constraint de `status` - nunca se asume el nombre por convencion), se
-- dropea, se saca el NOT NULL de la columna, y se vuelve a crear la foreign key
-- con on delete set null y un nombre explicito y estable
-- (`<tabla>_<columna>_fkey`) para que quede predecible de aca en adelante.
--
-- QUE NO SE TOCA (ya estaba bien, verificado antes de escribir esta migracion):
--   time_bank_benefits.owner_id / approved_by_adult_id  (0003, ya set null)
--   routine_overrides.created_by                        (0004, ya set null)
--   adult_invitations.accepted_by_user_id                (0004, ya set null)
--   family_activity_events.created_by                    (0011, ya set null)
--
-- SEGURA DE APLICAR HOY: aditiva, no borra ni transforma ningun dato existente,
-- no cambia ninguna policy de RLS. El unico efecto observable hasta que exista
-- la etapa 2 es que, si alguien borrara una cuenta manualmente hoy desde el
-- dashboard de Supabase, el contenido familiar ya no se borraria con ella - una
-- mejora, no una regresion.
--
-- VERIFICACION MANUAL DESPUES DE APLICAR (no se ejecuta como parte de esta
-- migracion; correr contra un entorno de prueba, sumar a la proxima revision
-- del archivo supabase/0008_0012_routine_sessions_activity_test.sql cuando se
-- escriba la etapa 2):
--
--   select
--     conrelid::regclass as table_name,
--     conname,
--     confdeltype  -- debe ser 'n' (set null) en las 15 columnas de esta lista
--   from pg_constraint
--   where contype = 'f'
--     and confrelid = 'auth.users'::regclass
--   order by 1, 2;
--
--   select table_name, column_name, is_nullable  -- debe ser 'YES' en las 15
--   from information_schema.columns
--   where table_schema = 'public'
--     and (table_name, column_name) in (
--       ('families','owner'), ('profiles','owner'), ('routines','owner'),
--       ('routine_steps','owner'), ('routine_sessions','owner'),
--       ('habits','owner'), ('habit_activations','owner'),
--       ('habit_progress','owner'), ('notification_preferences','owner'),
--       ('emotion_check_ins','owner'), ('support_requests','owner'),
--       ('story_progress','owner'), ('audit_logs','owner'),
--       ('audit_logs','actor_id'), ('adult_invitations','invited_by_user_id')
--     );
--
-- ROLLBACK: revertir cada columna a `on delete cascade` y reponer NOT NULL
-- (bloque comentado al final de este archivo). Aviso importante: si para el
-- momento de revertir ya existe alguna fila con una de estas columnas en NULL
-- (porque esta migracion ya cumplio su proposito y alguna cuenta ya se borro),
-- reponer NOT NULL va a fallar hasta decidir que valor poner en esas filas -
-- no es un rollback ciego.

do $$
declare
  target record;
  constraint_names text[];
  new_constraint_name text;
begin
  for target in
    select * from (values
      ('families', 'owner'),
      ('profiles', 'owner'),
      ('routines', 'owner'),
      ('routine_steps', 'owner'),
      ('routine_sessions', 'owner'),
      ('habits', 'owner'),
      ('habit_activations', 'owner'),
      ('habit_progress', 'owner'),
      ('notification_preferences', 'owner'),
      ('emotion_check_ins', 'owner'),
      ('support_requests', 'owner'),
      ('story_progress', 'owner'),
      ('audit_logs', 'owner'),
      ('audit_logs', 'actor_id'),
      ('adult_invitations', 'invited_by_user_id')
    ) as t(table_name, column_name)
  loop
    -- Descubrir la foreign key real de (target.table_name, target.column_name)
    -- hacia auth.users - nunca asumir el nombre. Exige exactamente una FK de una
    -- sola columna; si hay cero o mas de una, corta la migracion en vez de
    -- adivinar (mismo criterio que 0010_invitation_codes.sql).
    select array_agg(pg_constraint.conname)
    into constraint_names
    from pg_constraint
    join pg_attribute
      on pg_attribute.attrelid = pg_constraint.conrelid
     and pg_attribute.attnum = any (pg_constraint.conkey)
    where pg_constraint.conrelid = format('public.%I', target.table_name)::regclass
      and pg_constraint.contype = 'f'
      and pg_constraint.confrelid = 'auth.users'::regclass
      and pg_attribute.attname = target.column_name
      and array_length(pg_constraint.conkey, 1) = 1;

    if constraint_names is null or array_length(constraint_names, 1) = 0 then
      raise exception
        'No se encontro una foreign key de una sola columna desde %.% hacia auth.users - resolver manualmente antes de volver a correr esta migracion.',
        target.table_name, target.column_name;
    elsif array_length(constraint_names, 1) > 1 then
      raise exception
        'Se encontro mas de una foreign key desde %.% hacia auth.users (%), no se adivina cual reemplazar.',
        target.table_name, target.column_name, array_to_string(constraint_names, ', ');
    end if;

    new_constraint_name := format('%s_%s_fkey', target.table_name, target.column_name);

    execute format(
      'alter table public.%I drop constraint %I',
      target.table_name, constraint_names[1]
    );
    execute format(
      'alter table public.%I alter column %I drop not null',
      target.table_name, target.column_name
    );
    execute format(
      'alter table public.%I add constraint %I foreign key (%I) references auth.users(id) on delete set null',
      target.table_name, new_constraint_name, target.column_name
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- ROLLBACK (manual - correr solo si hay que revertir esta migracion; ver el
-- aviso sobre columnas ya en NULL en el comentario de arriba antes de correrlo)
-- ---------------------------------------------------------------------------
--
-- do $$
-- declare
--   target record;
-- begin
--   for target in
--     select * from (values
--       ('families', 'owner'), ('profiles', 'owner'), ('routines', 'owner'),
--       ('routine_steps', 'owner'), ('routine_sessions', 'owner'),
--       ('habits', 'owner'), ('habit_activations', 'owner'),
--       ('habit_progress', 'owner'), ('notification_preferences', 'owner'),
--       ('emotion_check_ins', 'owner'), ('support_requests', 'owner'),
--       ('story_progress', 'owner'), ('audit_logs', 'owner'),
--       ('audit_logs', 'actor_id'), ('adult_invitations', 'invited_by_user_id')
--     ) as t(table_name, column_name)
--   loop
--     execute format(
--       'alter table public.%I drop constraint %I',
--       target.table_name, format('%s_%s_fkey', target.table_name, target.column_name)
--     );
--     execute format(
--       'alter table public.%I alter column %I set not null',
--       target.table_name, target.column_name
--     );
--     execute format(
--       'alter table public.%I add constraint %I foreign key (%I) references auth.users(id) on delete cascade',
--       target.table_name, format('%s_%s_fkey', target.table_name, target.column_name), target.column_name
--     );
--   end loop;
-- end $$;
