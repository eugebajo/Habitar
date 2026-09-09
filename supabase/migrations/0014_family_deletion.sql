-- Etapa 2 de 3 del borrado de cuenta in-app (ver docs/inventario-datos.md,
-- Parte 5, y la conversacion de diseno que la precede - etapa 1 fue
-- 0013_decouple_owner_from_auth_users.sql). Esta etapa agrega la tabla y las
-- funciones nuevas; no toca ninguna UI todavia (etapa 3).
--
-- REQUISITO DE ORDEN: aplicar despues de 0013, y solo despues de que 0013
-- este aplicada (delete_family/delete_my_account dependen de que owner ya
-- pueda ser null sin romper nada - ver el aviso de orden de despliegue en el
-- encabezado de 0013).
--
-- QUE AGREGA
--
-- 1. public.families.deleted_at - marca de cuando se pidio el borrado.
--    Deliberadamente una columna nueva y no una reutilizacion de updated_at:
--    updated_at ya se usa para otras cosas y no queremos que un futuro update
--    no relacionado corra el reloj de los 30 dias por accidente.
--
-- 2. public.departed_family_notices - tabla nueva, chica a proposito. Una fila
--    por adulto al que se le borro el acceso a una familia que no fue quien
--    la borro. Guarda exactamente tres cosas ademas del id: a quien avisar
--    (user_id), el nombre de la familia (snapshot de texto, no una foreign
--    key - la familia puede purgarse fisicamente despues y el aviso tiene que
--    sobrevivir a eso) y cuando. Nada de perfiles, rutinas, ni ningun dato de
--    un nino - a proposito, para no reintroducir por la puerta de atras lo
--    mismo que family_members.delete() esta cortando. RLS exige
--    user_id = auth.uid() tanto para leer como para borrar (el borrado es
--    como la app la descarta despues de mostrarla una vez); no hay policy de
--    insert/update para `authenticated` - solo delete_family (security
--    definer, corre como dueno de la tabla) escribe aca.
--
-- 3. purge_expired_deleted_families() - la purga de los 30 dias, autolimpiante
--    como se pidio: sin pg_cron, sin funcion programada nueva. Un delete
--    sobre families con mas de 30 dias en status='deleted' Y sin ninguna fila
--    en family_members - esto segundo es la salvaguarda real, no un detalle:
--    status/deleted_at por si solos no garantizan que la familia paso por
--    delete_family (un update manual desde el dashboard, o una migracion
--    futura que toque esas columnas por otro motivo, alcanzarian para
--    calificar), y una familia viva siempre tiene al menos un adulto. El
--    cascade existente de family_id (sin cambios desde 0001/0004) se encarga
--    de todo lo de abajo. Se llama desde dos lugares para que el plazo de 30
--    dias sea real incluso si nadie vuelve a borrar una familia en mucho
--    tiempo:
--      - delete_family(), cada vez que se borra CUALQUIER familia;
--      - complete_routine_session(), porque es por lejos la RPC que mas se
--        llama en toda la app (cada vez que cualquier chico termina cualquier
--        rutina, en cualquier familia) - la purga corre en la practica todo
--        el tiempo que haya uso normal, no depende de que alguien
--        puntualmente decida borrar algo. No es llamable directamente por un
--        cliente (revoke de public/anon/authenticated); solo las dos
--        funciones de arriba la invocan internamente.
--    En ambos lugares la llamada esta envuelta en su propio begin/exception:
--    si la purga falla por lo que sea, se registra como warning y la funcion
--    que la llamo sigue como si nada - completar el paso de un chico, o
--    borrar la familia que alguien realmente pidio borrar, nunca dependen de
--    que la purga (un mantenimiento oportunista, no un requisito) salga bien.
--
-- 4. delete_family(target_family_id) - solo el rol 'owner' de esa familia
--    puede llamarla. Corre la purga de arriba primero, marca la familia como
--    'deleted' con su deleted_at, escribe un aviso en
--    departed_family_notices para cada adulto que no sea quien esta
--    borrando, y borra las filas de family_members de esa familia - eso
--    corta el acceso por RLS al instante para todos ("family members can
--    view X" en cada tabla exige una fila de family_members que ya no
--    existe), no es solo un filtro de UI. La fila fisica de families (y todo
--    lo que cuelga de family_id/profile_id/etc., sin cambios) sigue viva
--    hasta que la purga la alcance. Idempotente: llamarla dos veces, o
--    llamarla despues de que la purga ya se adelanto, devuelve
--    'already_deleted' en vez de fallar.
--
-- 5. transfer_family_ownership(new_owner_user_id) - solo quien ya es 'owner'
--    puede llamarla, solo hacia otro adulto que ya sea miembro de la misma
--    familia. Bloquea las dos filas de family_members involucradas (la de
--    quien transfiere y la del destino) en un orden fijo por user_id antes de
--    validar nada, para que dos transferencias concurrentes desde el mismo
--    dueno hacia destinos distintos no puedan dejar dos 'owner' (o ninguno),
--    y para que dos llamadas con destinos cruzados no puedan bloquearse
--    mutuamente. Promueve al elegido a 'owner' y degrada a quien transfiere a
--    'parent', en la misma transaccion. No toca families.owner (esa columna
--    quedo como historial puro desde la 0013 - ni antes ni ahora la usa
--    ningun control de acceso).
--
-- 6. delete_my_account() - sin parametros, opera sobre auth.uid(). Si quien
--    llama es 'owner' de una familia con otros adultos adentro, corta con
--    'OWNER_MUST_TRANSFER_OR_DELETE_FAMILY' en vez de decidir por su cuenta -
--    la app tiene que forzar la eleccion (transferir o borrar todo) antes de
--    volver a intentar. Si es el unico adulto de su familia, la llamada a
--    delete_family ya la hace esta misma funcion - "borrar mi cuenta" y
--    "borrar la familia" terminan siendo la misma operacion explicita en ese
--    caso, nunca un efecto secundario silencioso de una foreign key. Al
--    final borra la fila de auth.users - eso ya dispara el on delete set
--    null de la 0013 en todo lo que ese adulto haya creado, y el on delete
--    cascade (sin cambios) de su propia fila de family_members si todavia
--    quedaba alguna.
--
-- QUE NO HACE ESTA ETAPA: no expone nada de esto en Flutter (etapa 3), no
-- envia ningun email ni notificacion push a los adultos avisados - se
-- enteran la proxima vez que abran la app y departed_family_notices tenga
-- una fila para ellos.

-- ---------------------------------------------------------------------------
-- 1. families.deleted_at + indice parcial para la purga
-- ---------------------------------------------------------------------------

alter table public.families add column if not exists deleted_at timestamptz;

create index if not exists families_pending_purge_idx
  on public.families (deleted_at)
  where status = 'deleted';

-- ---------------------------------------------------------------------------
-- 2. departed_family_notices
-- ---------------------------------------------------------------------------

create table if not exists public.departed_family_notices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  family_name text not null,
  deleted_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

comment on table public.departed_family_notices is
  'No guarda ningun dato de un perfil infantil. Solo a quien avisar, el '
  'nombre de la familia que se elimino, y cuando - suficiente para mostrar '
  'un aviso, nada mas.';

alter table public.departed_family_notices enable row level security;

create index if not exists departed_family_notices_user_idx
  on public.departed_family_notices (user_id);

drop policy if exists "adults can view their own departure notices"
  on public.departed_family_notices;
create policy "adults can view their own departure notices"
on public.departed_family_notices for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "adults can dismiss their own departure notices"
  on public.departed_family_notices;
create policy "adults can dismiss their own departure notices"
on public.departed_family_notices for delete
to authenticated
using (user_id = auth.uid());

-- Deliberadamente sin policy de insert/update para `authenticated`: nadie
-- excepto delete_family (security definer, corre como dueno de la tabla,
-- no sujeto a RLS) escribe aca. Un adulto no puede fabricarse ni editar su
-- propio aviso. Mismo patron de revoke/grant explicito que
-- 0011_family_activity_events.sql:84-87 en vez de asumir privilegios por
-- default de una tabla nueva.
revoke all on public.departed_family_notices from anon;
revoke insert, update on public.departed_family_notices from authenticated;
grant select, delete on public.departed_family_notices to authenticated;

-- ---------------------------------------------------------------------------
-- 3. purge_expired_deleted_families - la purga de los 30 dias
-- ---------------------------------------------------------------------------

create or replace function public.purge_expired_deleted_families()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- La cuarta condicion es la salvaguarda real, no las primeras tres: nada
  -- ata status='deleted'/deleted_at a haber pasado por delete_family - un
  -- update manual desde el dashboard, o una migracion futura que toque estas
  -- columnas por otro motivo, alcanzarian para que esta funcion borre una
  -- familia viva con sus perfiles y rutinas adentro. delete_family es lo
  -- unico que ademas deja a la familia sin ninguna fila en family_members;
  -- una familia real siempre tiene al menos un adulto. Exigir las dos cosas
  -- a la vez es barato (el mismo indice unico de family_members(family_id,
  -- user_id) de 0001 ya sirve para este anti-join) contra el error mas caro
  -- posible de todo este sistema.
  delete from public.families
  where status = 'deleted'
    and deleted_at is not null
    and deleted_at < now() - interval '30 days'
    -- Salvaguarda adicional: asegurar que NO exista ninguna fila en
    -- public.family_members para esta familia. Una familia "viva" siempre
    -- tiene al menos un adulto; delete_family deja la familia sin filas en
    -- family_members, por eso exigir este anti-join protege contra un
    -- update manual o una migracion futura que pudiera marcar status/deleted_at
    -- sin pasar por delete_family.
    and not exists (
      select 1
      from public.family_members
      where family_members.family_id = families.id
    );
end;
$$;

-- No llamable directamente por ningun cliente - solo delete_family y
-- complete_routine_session la invocan internamente (ver el encabezado de
-- este archivo para por que esta enganchada en ambas).
revoke all on function public.purge_expired_deleted_families()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. delete_family
-- ---------------------------------------------------------------------------

create or replace function public.delete_family(
  target_family_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  family_row public.families%rowtype;
  member_row record;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if target_family_id is null then
    raise exception 'FAMILY_ID_REQUIRED' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.family_members
    where family_members.family_id = target_family_id
      and family_members.user_id = current_user_id
      and family_members.role = 'owner'
  ) then
    raise exception 'FAMILY_DELETE_FORBIDDEN' using errcode = '42501';
  end if;

  -- Autolimpiante: antes de borrar esta familia, purgar cualquier otra (o
  -- esta misma, si ya paso el plazo de una llamada anterior) cuyos 30 dias
  -- ya vencieron. Sin esto, el plazo solo se cumpliria cuando alguien
  -- vuelva a pedir un borrado - ver el encabezado de este archivo.
  --
  -- Aislada en su propio bloque: la purga es oportunista, un best-effort de
  -- limpieza, nunca un requisito para que ESTE borrado (el que el llamador
  -- realmente pidio) tenga exito. Si falla por lo que sea, se registra como
  -- warning y se sigue - jamas debe poder tumbar el borrado real.
  begin
    perform public.purge_expired_deleted_families();
  exception
    when others then
      raise warning 'purge_expired_deleted_families fallo dentro de delete_family: %', sqlerrm;
  end;

  select * into family_row
  from public.families
  where id = target_family_id
  for update;

  if not found or family_row.status = 'deleted' then
    -- Ya purgada (sus propios 30 dias ya habian vencido) o ya marcada como
    -- eliminada por una llamada anterior - en ambos casos, lo que el
    -- llamador pedia (que esta familia deje de existir) ya es cierto.
    return jsonb_build_object(
      'status', 'already_deleted',
      'family_id', target_family_id
    );
  end if;

  -- Avisar a todos los demas adultos antes de cortarles el acceso - una vez
  -- que sus filas de family_members desaparezcan, no queda ningun otro
  -- registro de que alguna vez pertenecieron a esta familia. Excluye a quien
  -- esta borrando: ya sabe lo que hizo.
  for member_row in
    select user_id
    from public.family_members
    where family_id = target_family_id
      and user_id <> current_user_id
  loop
    insert into public.departed_family_notices (user_id, family_name, deleted_at)
    values (member_row.user_id, family_row.name, now());
  end loop;

  update public.families
  set status = 'deleted',
      deleted_at = now(),
      updated_at = now()
  where id = target_family_id;

  -- Corte de acceso real, no solo ocultamiento en la UI: sin ninguna fila de
  -- family_members, las policies "family members can view/manage X" de cada
  -- tabla dejan de encontrar a cualquiera de estos adultos, incluso por una
  -- llamada directa a la API, ya - no en 30 dias.
  delete from public.family_members
  where family_id = target_family_id;

  return jsonb_build_object('status', 'deleted', 'family_id', target_family_id);
end;
$$;

revoke all on function public.delete_family(uuid) from public, anon;
grant execute on function public.delete_family(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. transfer_family_ownership
-- ---------------------------------------------------------------------------

create or replace function public.transfer_family_ownership(
  new_owner_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  target_family_id uuid;
  current_membership record;
  target_membership record;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if new_owner_user_id is null then
    raise exception 'NEW_OWNER_REQUIRED' using errcode = '22023';
  end if;

  if new_owner_user_id = current_user_id then
    raise exception 'TRANSFER_SELF_FORBIDDEN' using errcode = '22023';
  end if;

  -- Un adulto pertenece a lo sumo a una familia (accept_family_invitation_by_code
  -- en 0010 ya lo garantiza al aceptar una invitacion), asi que no hace falta
  -- que el llamador indique target_family_id - se deriva de su propia fila.
  -- Lectura sin lock, solo para saber en que familia estamos - el chequeo de
  -- rol real se hace mas abajo, sobre la fila ya bloqueada, no sobre esta.
  select family_id
  into target_family_id
  from public.family_members
  where user_id = current_user_id
  limit 1;

  if target_family_id is null then
    raise exception 'TRANSFER_FORBIDDEN' using errcode = '42501';
  end if;

  -- Bloquear las dos filas de family_members involucradas - la de quien
  -- transfiere y la de a quien - en un orden fijo por user_id, sin importar
  -- cual de las dos sea "actual" y cual "nueva". Sin esto, dos transferencias
  -- concurrentes desde el mismo dueno hacia destinos distintos podrian
  -- dejar dos 'owner' (o ninguno): ambas leen la fila del dueno sin bloqueo,
  -- ambas la ven todavia como 'owner', ambas promueven a su destino. Bloquear
  -- primero la fila del dueno serializa eso - la segunda transferencia queda
  -- esperando hasta que la primera termine, y al reanudar ya no encuentra
  -- role='owner' en esa fila. El MISMO orden (por user_id, no "primero la
  -- del que llama") en las dos ramas del if evita ademas un deadlock entre
  -- dos llamadas concurrentes con destinos cruzados.
  -- Lock both involved family_members rows in a stable order by user_id.
  -- Additionally lock the caller's own row explicitly to prevent two
  -- concurrent transfers from the same owner from racing: without locking
  -- the caller's row two concurrent transfers could both read role='owner'
  -- and proceed, potentially leaving two owners or none. The order by
  -- user_id is kept identical in both branches to avoid deadlocks when two
  -- sessions attempt cross transfers.
  if current_user_id < new_owner_user_id then
    perform 1 from public.family_members
    where family_id = target_family_id and user_id = current_user_id
    for update;
    perform 1 from public.family_members
    where family_id = target_family_id and user_id = new_owner_user_id
    for update;
  else
    perform 1 from public.family_members
    where family_id = target_family_id and user_id = new_owner_user_id
    for update;
    perform 1 from public.family_members
    where family_id = target_family_id and user_id = current_user_id
    for update;
  end if;

  -- Extra safeguard: re-lock the caller's family_members row explicitly with
  -- FOR UPDATE to ensure the caller's state (role) is observed under lock.
  -- This is redundant if the caller's row was already locked above, but
  -- being explicit makes the intention clear and robust across minor
  -- refactorings of the lock ordering logic.
  perform 1 from public.family_members
  where family_id = target_family_id and user_id = current_user_id
  for update;

  select *
  into current_membership
  from public.family_members
  where family_id = target_family_id
    and user_id = current_user_id;

  if not found or current_membership.role <> 'owner' then
    raise exception 'TRANSFER_FORBIDDEN' using errcode = '42501';
  end if;

  select *
  into target_membership
  from public.family_members
  where family_id = target_family_id
    and user_id = new_owner_user_id;

  if not found then
    raise exception 'TRANSFER_TARGET_NOT_MEMBER' using errcode = '22023';
  end if;

  update public.family_members
  set role = 'owner'
  where family_id = target_family_id
    and user_id = new_owner_user_id;

  update public.family_members
  set role = 'parent'
  where family_id = target_family_id
    and user_id = current_user_id;

  return jsonb_build_object(
    'status', 'transferred',
    'family_id', target_family_id,
    'new_owner_user_id', new_owner_user_id
  );
end;
$$;

revoke all on function public.transfer_family_ownership(uuid) from public, anon;
grant execute on function public.transfer_family_ownership(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. delete_my_account
-- ---------------------------------------------------------------------------

create or replace function public.delete_my_account()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  owner_membership record;
  other_member_count integer;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  select *
  into owner_membership
  from public.family_members
  where user_id = current_user_id
    and role = 'owner'
  limit 1;

  if found then
    select count(*)
    into other_member_count
    from public.family_members
    where family_id = owner_membership.family_id
      and user_id <> current_user_id;

    if other_member_count > 0 then
      -- No decidir por el usuario: la app tiene que forzar "transferir" o
      -- "borrar todo el espacio familiar" antes de volver a llamar a esta
      -- funcion.
      raise exception 'OWNER_MUST_TRANSFER_OR_DELETE_FAMILY' using errcode = '42501';
    end if;

    -- Unico adulto de su familia: borrar la cuenta personal ES borrar la
    -- familia. Pasa por el mismo camino explicito y auditable que cualquier
    -- otro borrado de familia, en vez de tener una segunda logica paralela
    -- aca.
    perform public.delete_family(owner_membership.family_id);
  end if;

  -- Requiere que el rol que ejecuta las migraciones tenga privilegio de
  -- delete sobre auth.users - cierto para el rol `postgres` en un proyecto
  -- de Supabase estandar (mismo patron que usan varios tutoriales de
  -- "borrar mi cuenta" de la comunidad de Supabase), pero no lo pude
  -- verificar corriendo esto contra el proyecto real. Si al aplicar esta
  -- migracion la funcion se crea sin error pero esta linea falla en
  -- tiempo de ejecucion con un error de permisos, la alternativa es mover
  -- solo este delete a una Edge Function con la service_role key - el
  -- resto de la funcion (las validaciones y delete_family) no cambiaria.
  --
  -- A PROPOSITO sin bloque exception alrededor de esta linea (a diferencia
  -- de los dos que envuelven la purga, mas arriba y en complete_routine_
  -- session): si este delete falla, TIENE que abortar toda la transaccion.
  -- Una llamada a RPC de PostgREST es una unica transaccion de punta a
  -- punta; una excepcion sin atrapar en cualquier punto de esta funcion
  -- deshace todo lo que ya hizo en esta misma llamada, incluido el
  -- perform delete_family(...) de arriba (marcar la familia eliminada,
  -- escribir los avisos, borrar family_members). No hay ningun estado
  -- intermedio posible - o se borra todo (familia y cuenta), o no se borra
  -- nada. Envolver esta linea en un exception que la atrape y siga NO se
  -- debe hacer nunca: eso es exactamente lo que abriria la posibilidad de
  -- "familia borrada, cuenta viva".
  delete from auth.users where id = current_user_id;

  return jsonb_build_object('status', 'deleted', 'user_id', current_user_id);
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ---------------------------------------------------------------------------
-- 7. complete_routine_session - agrega el gancho de purga, nada mas cambia
-- ---------------------------------------------------------------------------
--
-- Recreada por completo porque create or replace function reemplaza el
-- cuerpo entero; el resto de esta funcion es una copia exacta de
-- 0011_family_activity_events.sql:106-215, sin ningun otro cambio.

create or replace function public.complete_routine_session(
  target_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  session_data record;
  event_id uuid;
  completed_at_value timestamptz;
begin
  -- Unico cambio respecto a 0011: la purga de los 30 dias enganchada aca
  -- porque esta es la RPC que mas se llama en toda la app - ver el
  -- encabezado de este archivo. No depende de current_user_id ni de nada
  -- especifico de esta sesion, asi que corre antes de cualquier chequeo.
  --
  -- Aislada en su propio bloque a proposito: completar el paso de un chico
  -- nunca debe poder fallar ni demorarse por un problema de la purga. Si
  -- purge_expired_deleted_families() lanza cualquier excepcion, se atrapa
  -- aca, se registra como warning, y esta funcion sigue exactamente como si
  -- la purga no existiera. No sacar este bloque exception - sin el, un
  -- fallo de la purga tumbaria la finalizacion real de la rutina.
  begin
    perform public.purge_expired_deleted_families();
  exception
    when others then
      raise warning 'purge_expired_deleted_families fallo dentro de complete_routine_session: %', sqlerrm;
  end;

  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if target_session_id is null then
    raise exception 'SESSION_ID_REQUIRED' using errcode = '22023';
  end if;

  select
    rs.id as session_id,
    rs.session_status,
    rs.completed_at,
    rs.updated_at,
    r.id as routine_id,
    r.title as routine_title,
    p.id as profile_id,
    p.display_name as profile_display_name,
    p.family_id
  into session_data
  from public.routine_sessions as rs
  join public.routines as r on r.id = rs.routine_id
  join public.profiles as p on p.id = r.profile_id
  where rs.id = target_session_id
  for update of rs;

  if not found then
    raise exception 'SESSION_NOT_FOUND' using errcode = '02000';
  end if;

  if not exists (
    select 1
    from public.family_members as fm
    where fm.family_id = session_data.family_id
      and fm.user_id = current_user_id
      and fm.role in ('owner', 'parent', 'caregiver')
  ) then
    raise exception 'SESSION_COMPLETION_NOT_ALLOWED' using errcode = '42501';
  end if;

  if session_data.session_status = 'completed' then
    completed_at_value := coalesce(
      session_data.completed_at,
      session_data.updated_at,
      now()
    );
  else
    completed_at_value := now();

    update public.routine_sessions
    set session_status = 'completed',
        completed_at = completed_at_value,
        updated_at = completed_at_value
    where id = target_session_id;
  end if;

  insert into public.family_activity_events (
    family_id,
    profile_id,
    routine_id,
    session_id,
    kind,
    profile_display_name,
    routine_title,
    created_by,
    created_at
  )
  values (
    session_data.family_id,
    session_data.profile_id,
    session_data.routine_id,
    session_data.session_id,
    'routine_completed',
    session_data.profile_display_name,
    session_data.routine_title,
    current_user_id,
    completed_at_value
  )
  on conflict (session_id, kind) do nothing;

  select fae.id
  into event_id
  from public.family_activity_events as fae
  where fae.session_id = target_session_id
    and fae.kind = 'routine_completed'
  limit 1;

  return jsonb_build_object(
    'session_id', target_session_id,
    'status', 'completed',
    'completed_at', completed_at_value,
    'event_id', event_id
  );
end;
$$;

revoke all on function public.complete_routine_session(uuid)
  from public, anon;
grant execute on function public.complete_routine_session(uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- VERIFICACION MANUAL DESPUES DE APLICAR
-- ---------------------------------------------------------------------------
--
-- 1. Estructura:
--   select column_name, is_nullable from information_schema.columns
--   where table_schema = 'public' and table_name = 'families' and column_name = 'deleted_at';
--
--   select policyname, cmd, roles from pg_policies
--   where schemaname = 'public' and tablename = 'departed_family_notices';
--   -- Debe mostrar exactamente dos policies: select y delete, ambas
--   -- "using (user_id = auth.uid())". Ninguna de insert/update.
--
--   select grantee, privilege_type from information_schema.role_table_grants
--   where table_schema = 'public' and table_name = 'departed_family_notices'
--   and grantee in ('anon', 'authenticated');
--   -- authenticated: solo select y delete. anon: ninguno.
--
--   select p.proname, p.prosecdef from pg_proc p
--   join pg_namespace n on n.oid = p.pronamespace
--   where n.nspname = 'public'
--   and p.proname in ('delete_family', 'transfer_family_ownership',
--                      'delete_my_account', 'purge_expired_deleted_families',
--                      'complete_routine_session');
--   -- Las cinco con prosecdef = true.
--
-- 2. Comportamiento (con JWTs de prueba, contra una base descartable):
--   - Concurrencia en transfer_family_ownership: un mismo 'owner' con dos
--     adultos B y C en su familia, lanzando transfer_family_ownership(B) y
--     transfer_family_ownership(C) al mismo tiempo (dos conexiones/sesiones
--     distintas) - al terminar ambas, exactamente uno de B o C debe ser
--     'owner' (la otra llamada debe haber fallado con TRANSFER_FORBIDDEN al
--     reanudar y encontrar que quien transfiere ya no es 'owner'), nunca los
--     dos a la vez ni ninguno.
--   - delete_family llamada por un 'parent' o 'caregiver' (no 'owner') falla
--     con FAMILY_DELETE_FORBIDDEN.
--   - delete_family llamada dos veces seguidas: la segunda devuelve
--     'already_deleted', no falla.
--   - Despues de delete_family, ningun miembro anterior puede volver a leer
--     profiles/routines/etc. de esa familia (family_members ya no existe).
--   - departed_family_notices tiene una fila por cada adulto EXCEPTO quien
--     borro, con el nombre de la familia y una fecha reciente.
--   - transfer_family_ownership hacia alguien que no es miembro de la misma
--     familia falla con TRANSFER_TARGET_NOT_MEMBER.
--   - delete_my_account llamada por un 'owner' con otros adultos en la
--     familia falla con OWNER_MUST_TRANSFER_OR_DELETE_FAMILY, sin borrar nada.
--   - delete_my_account llamada por el unico adulto de su familia borra la
--     familia (families.status = 'deleted') y despues la fila de auth.users.
--   - Salvaguarda de la purga (la que realmente importa probar): insertar
--     manualmente una fila en families con status='deleted' y deleted_at
--     hace 31 dias, PERO dejando sus filas de family_members intactas
--     (simulando un update manual desde el dashboard, no un delete_family
--     real) - llamar a complete_routine_session sobre cualquier sesion real
--     y confirmar que esa familia de prueba SIGUE existiendo despues. Recien
--     al borrar tambien sus filas de family_members a mano, la siguiente
--     purga si se la lleva.
--   - Aislamiento de la purga: renombrar temporalmente
--     purge_expired_deleted_families (o hacer que su delete falle a
--     proposito, ej. una columna inexistente) y confirmar que
--     complete_routine_session sobre una sesion real sigue completando el
--     paso con exito (con un warning en los logs), y que delete_family sobre
--     una familia real sigue borrandola con exito. Ninguna de las dos debe
--     fallar por culpa de la purga.
--
-- ROLLBACK (manual):
--   drop function if exists public.delete_my_account();
--   drop function if exists public.transfer_family_ownership(uuid);
--   drop function if exists public.delete_family(uuid);
--   drop function if exists public.purge_expired_deleted_families();
--   drop table if exists public.departed_family_notices;
--   alter table public.families drop column if exists deleted_at;
--   -- Y volver a aplicar el create or replace function de
--   -- complete_routine_session tal como queda en
--   -- 0011_family_activity_events.sql (sin el perform de purga), para
--   -- restaurar el cuerpo original.
