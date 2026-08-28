-- Local verification plan for 0008, 0011 and 0012 (0011/0012 renumbered
-- from what was originally a single 0009 file, then split in two per
-- deployment-order review).
--
-- Run only against a disposable/local Supabase database. Do not run against
-- production data.
--
-- IMPORTANT: 0012 locks down direct routine_sessions writes and must only be
-- applied, even locally, after exercising the Flutter RPC path. If you are
-- verifying 0011 alone (the normal case before a Flutter release ships),
-- skip every check below marked "(0012 only)".
--
-- This file intentionally contains no credentials and no service_role key.
-- It is a checklist-style SQL harness because this repo does not currently
-- include a Supabase SQL test runner.

begin;

-- 1. Structural checks.
select
  column_name,
  data_type,
  is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'routine_sessions'
  and column_name in ('session_date', 'completed_at')
order by column_name;

select
  conname,
  contype
from pg_constraint
where conrelid = 'public.routine_sessions'::regclass
  and conname = 'routine_sessions_unique_routine_session_date';

select
  policyname,
  cmd,
  roles
from pg_policies
where schemaname = 'public'
  and tablename = 'family_activity_events';

-- 1b. (0012 only) routine_sessions should have three narrow policies instead
-- of the single 0007 "authorized adults can manage routine sessions" FOR ALL
-- one. Before 0012 is applied, this will still show the original policy —
-- that is expected and correct.
select
  policyname,
  cmd,
  roles
from pg_policies
where schemaname = 'public'
  and tablename = 'routine_sessions'
order by policyname;

-- 2. Direct activity writes must remain unavailable to ordinary clients.
select
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name = 'family_activity_events'
  and grantee in ('anon', 'authenticated')
order by grantee, privilege_type;

-- 3. RPC definitions should exist with hardened properties.
select
  p.proname,
  p.prosecdef as security_definer,
  p.proconfig
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_or_create_routine_session',
    'complete_routine_session'
  )
order by p.proname;

-- 4. Manual behavioral checks to run with authenticated test JWTs:
-- - two concurrent calls to get_or_create_routine_session(routine_id, date)
--   return the same session_id;
-- - a completed session does not allow another routine_sessions row with the
--   same (routine_id, session_date);
-- - get_or_create_routine_session allows a new row for the next session_date;
-- - complete_routine_session(session_id) creates exactly one
--   family_activity_events row, and the response includes completed_at;
-- - calling complete_routine_session(session_id) twice returns the same
--   completed session state and does not duplicate activity;
-- - anon cannot select/insert/update/delete family_activity_events;
-- - a member of another family cannot select or complete the session;
-- - archiving a routine leaves family_activity_events readable by family
--   members with routine_title/profile_display_name snapshots intact;
-- - (0012 only) an authenticated adult UPDATEing their own routine_sessions
--   row directly with session_status = 'completed' is rejected by RLS;
-- - (0012 only) the same adult can still directly UPDATE the row for
--   pause/postpone/step-progress changes that do not set session_status to
--   'completed' (unchanged from 0007).

rollback;
