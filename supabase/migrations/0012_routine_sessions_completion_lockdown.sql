-- ============================================================================
-- DO NOT APPLY YET.
--
-- Apply this file only after the Flutter release that calls
-- complete_routine_session (via SupabaseRoutineSessionRepository) is
-- published AND installed on devices completing routines in production.
--
-- Why: this migration removes the client's ability to set
-- routine_sessions.session_status = 'completed' through a direct
-- insert/update. Today's installed Flutter app (pre-RPC) completes a
-- session with exactly that kind of direct write. Applying this migration
-- before the RPC-calling release reaches devices means every child who
-- finishes their steps gets a permission error instead of a completed
-- routine, in production, immediately.
--
-- Safe order:
--   1. Apply 0011_family_activity_events.sql (additive, safe today).
--   2. Ship the Flutter version that calls complete_routine_session.
--   3. Confirm (Supabase logs, or just time + a support channel check) that
--      installed devices are on that version, or close enough that a
--      handful of stragglers completing a routine mid-rollout is an
--      acceptable, brief inconsistency.
--   4. Only then apply this file.
-- ============================================================================

-- Replaces the single 0007 "authorized adults can manage routine sessions"
-- (FOR ALL) policy with three narrower ones. Every previously allowed
-- operation remains allowed, with one exception: no direct client write
-- (insert or update) may set session_status to 'completed'. Only
-- complete_routine_session can make that transition, because SECURITY
-- DEFINER functions run as the function owner (the table owner), which
-- bypasses row level security entirely — this policy change does not affect
-- what the function itself can do.
--
-- Rollback notes:
--   drop policy if exists "authorized adults can insert routine sessions" on public.routine_sessions;
--   drop policy if exists "authorized adults can update routine sessions" on public.routine_sessions;
--   drop policy if exists "authorized adults can delete routine sessions" on public.routine_sessions;
--   -- then re-run the "authorized adults can manage routine sessions"
--   -- CREATE POLICY block from 0007_role_permissions_hardening.sql verbatim.

drop policy if exists "authorized adults can manage routine sessions"
  on public.routine_sessions;

create policy "authorized adults can insert routine sessions"
on public.routine_sessions for insert
to authenticated
with check (
  owner = auth.uid()
  and session_status <> 'completed'
  and exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

create policy "authorized adults can update routine sessions"
on public.routine_sessions for update
to authenticated
using (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  owner = auth.uid()
  and session_status <> 'completed'
  and exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

create policy "authorized adults can delete routine sessions"
on public.routine_sessions for delete
to authenticated
using (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);
