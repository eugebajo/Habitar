-- Adds family activity events and an atomic routine completion RPC.
-- Purely additive: creates a new table and a new function, touches nothing
-- that already exists. Safe to apply today, independently of what version of
-- Flutter is installed on any device — the app keeps working exactly as
-- before until a Flutter release actually calls complete_routine_session.
--
-- Renumbered from 0009 -> 0011: this file was written before 0010
-- (invitation codes) but 0010 was applied to remote first and 0009 never
-- was. Applying a lower-numbered migration after a higher one is confusing
-- for anyone reading the migrations folder chronologically and for tooling
-- that assumes monotonic order, so this file was renamed instead of applied
-- out of order. No SQL inside it changed because of the rename.
--
-- pgcrypto check: this file does not call public.digest or any other
-- pgcrypto function. gen_random_uuid() is pg_catalog, not pgcrypto, so no
-- schema qualification is needed here. (Verified against the same
-- extensions-vs-public finding recorded in 0010.)
--
-- Prerequisite: 0008_routine_session_completion.sql must already be applied.
-- This migration's RPC reads routine_sessions.completed_at and
-- routine_sessions.session_status, both added by 0008. If 0008 is not
-- applied yet, creating the function below will fail immediately (loud,
-- not silent) — run the preflight check first.
--
-- The direct-UPDATE completion gap (Flutter's upsert can still set
-- session_status = 'completed' without ever calling this RPC) is
-- deliberately NOT closed here. That change lives in
-- 0012_routine_sessions_completion_lockdown.sql and must not be applied
-- until the Flutter version that calls complete_routine_session is already
-- published and installed on devices — see that file's header.
--
-- No data is deleted. The table stores the minimum context needed for a
-- family-facing activity feed.
--
-- Rollback notes:
--   -- Roll back 0012 first if it was applied, then:
--   drop function if exists public.complete_routine_session(uuid);
--   drop table if exists public.family_activity_events;

-- ---------------------------------------------------------------------------
-- 1. family_activity_events
-- ---------------------------------------------------------------------------

create table if not exists public.family_activity_events (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  routine_id uuid references public.routines(id) on delete set null,
  session_id uuid references public.routine_sessions(id) on delete set null,
  kind text not null check (kind in ('routine_completed')),
  profile_display_name text not null,
  routine_title text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint family_activity_events_unique_session_kind unique (session_id, kind)
);

alter table public.family_activity_events enable row level security;

create index if not exists family_activity_events_family_created_idx
on public.family_activity_events (family_id, created_at desc);

create index if not exists family_activity_events_profile_created_idx
on public.family_activity_events (profile_id, created_at desc);

create index if not exists family_activity_events_routine_idx
on public.family_activity_events (routine_id);

drop policy if exists "family members can view activity events"
  on public.family_activity_events;

create policy "family members can view activity events"
on public.family_activity_events for select
to authenticated
using (
  exists (
    select 1
    from public.family_members as fm
    where fm.family_id = family_activity_events.family_id
      and fm.user_id = auth.uid()
  )
);

revoke all on public.family_activity_events from anon;
revoke insert, update, delete on public.family_activity_events
  from authenticated;
grant select on public.family_activity_events to authenticated;

-- ---------------------------------------------------------------------------
-- 2. complete_routine_session
-- ---------------------------------------------------------------------------

-- SECURITY DEFINER is used only for routine completion because this operation
-- must atomically lock the session, mark it completed, and write exactly one
-- activity event. RLS alone can protect direct table operations but cannot
-- guarantee this cross-table idempotent workflow when direct client calls race.
--
-- Hardened properties:
-- - fixed empty search_path;
-- - all tables schema-qualified;
-- - no dynamic SQL;
-- - caller identity comes only from auth.uid();
-- - caller must be owner/parent/caregiver in the session's family;
-- - Flutter cannot pass user_id, family_id, profile_id, names, or event text;
-- - response is minimal and contains no tokens or private account data.
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
