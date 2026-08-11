-- Adds a functional day to routine sessions and prepares atomic daily session
-- creation. This migration is additive and does not delete or rewrite user
-- content beyond deterministic backfill of new nullable columns.
--
-- Functional timezone: America/Asuncion.
-- The app treats the day as Paraguay's civil day. Backfill derives
-- session_date from created_at at time zone 'America/Asuncion', not from UTC.
--
-- Rollback notes:
--   drop function if exists public.get_or_create_routine_session(uuid, date);
--   alter table public.routine_sessions
--     drop constraint if exists routine_sessions_unique_routine_session_date;
--   drop index if exists public.routine_sessions_routine_session_date_idx;
--   alter table public.routine_sessions drop column if exists completed_at;
--   alter table public.routine_sessions drop column if exists session_date;

begin;

alter table public.routine_sessions
  add column if not exists session_date date;

alter table public.routine_sessions
  add column if not exists completed_at timestamptz;

update public.routine_sessions
set session_date = (created_at at time zone 'America/Asuncion')::date
where session_date is null;

update public.routine_sessions
set completed_at = coalesce(updated_at, created_at)
where completed_at is null
  and session_status = 'completed';

do $$
declare
  duplicate_count integer;
begin
  select count(*)
  into duplicate_count
  from (
    select routine_id, session_date
    from public.routine_sessions
    where routine_id is not null
      and session_date is not null
    group by routine_id, session_date
    having count(*) > 1
  ) duplicates;

  if duplicate_count > 0 then
    raise exception 'ROUTINE_SESSION_DUPLICATES_FOUND: merge duplicates before applying 0008'
      using errcode = '23505';
  end if;
end $$;

alter table public.routine_sessions
  alter column session_date
  set default ((now() at time zone 'America/Asuncion')::date);

alter table public.routine_sessions
  alter column session_date set not null;

create index if not exists routine_sessions_routine_session_date_idx
on public.routine_sessions (routine_id, session_date);

alter table public.routine_sessions
  drop constraint if exists routine_sessions_unique_routine_session_date;

alter table public.routine_sessions
  add constraint routine_sessions_unique_routine_session_date
  unique (routine_id, session_date);

-- SECURITY INVOKER is intentional here. RLS already protects session reads and
-- inserts by checking the caller's family membership and role. The initial
-- SELECT FOR UPDATE locks an existing row, but it cannot lock a row that does
-- not exist. The unique constraint plus unique_violation recovery is the real
-- concurrency guard for simultaneous creation attempts. This function can
-- return a completed session; callers must inspect session_status before
-- continuing the routine.
create or replace function public.get_or_create_routine_session(
  target_routine_id uuid,
  target_session_date date default ((now() at time zone 'America/Asuncion')::date)
)
returns public.routine_sessions
language plpgsql
security invoker
set search_path = ''
as $$
declare
  current_user_id uuid;
  session_row public.routine_sessions%rowtype;
  routine_row record;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if target_routine_id is null then
    raise exception 'ROUTINE_ID_REQUIRED' using errcode = '22023';
  end if;

  if target_session_date is null then
    raise exception 'SESSION_DATE_REQUIRED' using errcode = '22023';
  end if;

  select rs.*
  into session_row
  from public.routine_sessions as rs
  where rs.routine_id = target_routine_id
    and rs.session_date = target_session_date
  for update;

  if found then
    return session_row;
  end if;

  select
    r.id as routine_id,
    p.family_id as family_id
  into routine_row
  from public.routines as r
  join public.profiles as p on p.id = r.profile_id
  join public.family_members as fm on fm.family_id = p.family_id
  where r.id = target_routine_id
    and r.status = 'active'
    and p.status = 'active'
    and fm.user_id = current_user_id
    and fm.role in ('owner', 'parent', 'caregiver')
  limit 1;

  if not found then
    raise exception 'ROUTINE_NOT_AVAILABLE' using errcode = '42501';
  end if;

  begin
    insert into public.routine_sessions (
      owner,
      status,
      access_rules,
      routine_id,
      active_step_index,
      session_status,
      completed_step_ids,
      skipped_step_ids,
      extra_minutes_by_step_id,
      help_requested,
      session_date
    )
    values (
      current_user_id,
      'active',
      '[]'::jsonb,
      target_routine_id,
      0,
      'running',
      array[]::uuid[],
      array[]::uuid[],
      '{}'::jsonb,
      false,
      target_session_date
    )
    returning * into session_row;
  exception
    when unique_violation then
      select rs.*
      into session_row
      from public.routine_sessions as rs
      where rs.routine_id = target_routine_id
        and rs.session_date = target_session_date
      for update;

      if not found then
        raise exception 'ROUTINE_SESSION_CONFLICT_NOT_FOUND'
          using errcode = '23505';
      end if;
  end;

  return session_row;
end;
$$;

revoke all on function public.get_or_create_routine_session(uuid, date)
  from public, anon;
grant execute on function public.get_or_create_routine_session(uuid, date)
  to authenticated;

commit;
