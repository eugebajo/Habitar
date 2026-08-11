-- Hardens role-based RLS for internal testing without changing existing data.
-- Safe to run after 0001 -> 0006. No tables or records are dropped/deleted.

alter table public.profiles enable row level security;
alter table public.routine_sessions enable row level security;
alter table public.habits enable row level security;
alter table public.habit_progress enable row level security;
alter table public.support_requests enable row level security;
alter table public.time_bank_benefits enable row level security;

drop policy if exists "family scoped profiles" on public.profiles;
drop policy if exists "family members can view profiles" on public.profiles;
drop policy if exists "authorized adults can manage profiles" on public.profiles;

create policy "family members can view profiles"
on public.profiles for select
to authenticated
using (
  exists (
    select 1
    from public.family_members
    where family_members.family_id = profiles.family_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage profiles"
on public.profiles for all
to authenticated
using (
  exists (
    select 1
    from public.family_members
    where family_members.family_id = profiles.family_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  owner = auth.uid()
  and exists (
    select 1
    from public.family_members
    where family_members.family_id = profiles.family_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family scoped routine sessions" on public.routine_sessions;
drop policy if exists "family members can view routine sessions" on public.routine_sessions;
drop policy if exists "authorized adults can manage routine sessions" on public.routine_sessions;

create policy "family members can view routine sessions"
on public.routine_sessions for select
to authenticated
using (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage routine sessions"
on public.routine_sessions for all
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

drop policy if exists "family scoped habits" on public.habits;
drop policy if exists "family members can view habits" on public.habits;
drop policy if exists "authorized adults can manage habits" on public.habits;

create policy "family members can view habits"
on public.habits for select
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = habits.profile_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage habits"
on public.habits for all
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = habits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  owner = auth.uid()
  and exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = habits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family scoped habit progress" on public.habit_progress;
drop policy if exists "family members can view habit progress" on public.habit_progress;
drop policy if exists "authorized adults can manage habit progress" on public.habit_progress;

create policy "family members can view habit progress"
on public.habit_progress for select
to authenticated
using (
  exists (
    select 1
    from public.habits
    join public.profiles on profiles.id = habits.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where habits.id = habit_progress.habit_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage habit progress"
on public.habit_progress for all
to authenticated
using (
  exists (
    select 1
    from public.habits
    join public.profiles on profiles.id = habits.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where habits.id = habit_progress.habit_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  owner = auth.uid()
  and exists (
    select 1
    from public.habits
    join public.profiles on profiles.id = habits.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where habits.id = habit_progress.habit_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family scoped support requests" on public.support_requests;
drop policy if exists "family members can view support requests" on public.support_requests;
drop policy if exists "authorized adults can manage support requests" on public.support_requests;

create policy "family members can view support requests"
on public.support_requests for select
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = support_requests.profile_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage support requests"
on public.support_requests for all
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = support_requests.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  owner = auth.uid()
  and exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = support_requests.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family members can view time bank benefits"
  on public.time_bank_benefits;
drop policy if exists "authorized adults can insert time bank benefits"
  on public.time_bank_benefits;
drop policy if exists "authorized adults can update time bank benefits"
  on public.time_bank_benefits;
drop policy if exists "authorized adults can delete time bank benefits"
  on public.time_bank_benefits;

create policy "family members can view time bank benefits"
on public.time_bank_benefits for select
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = time_bank_benefits.profile_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can insert time bank benefits"
on public.time_bank_benefits for insert
to authenticated
with check (
  (approved_by_adult_id is null or approved_by_adult_id = auth.uid())
  and (owner_id is null or owner_id = auth.uid())
  and exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = time_bank_benefits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

create policy "authorized adults can update time bank benefits"
on public.time_bank_benefits for update
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = time_bank_benefits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  (approved_by_adult_id is null or approved_by_adult_id = auth.uid())
  and (owner_id is null or owner_id = auth.uid())
  and exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = time_bank_benefits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

create policy "authorized adults can delete time bank benefits"
on public.time_bank_benefits for delete
to authenticated
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = time_bank_benefits.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);
