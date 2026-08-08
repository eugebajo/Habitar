-- Family invitations and one-day routine overrides.
-- Rollback guidance: export adult_invitations and routine_overrides before dropping.

create table if not exists public.adult_invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  email text not null,
  role text not null default 'viewer',
  status text not null default 'pending',
  invited_by_user_id uuid not null,
  accepted_by_user_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.routine_overrides (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.routines(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  override_date date not null,
  override_type text not null,
  start_hour integer,
  start_minute integer,
  is_paused boolean not null default false,
  note text,
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (routine_id, override_date)
);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'adult_invitations_role_allowed'
  ) then
    alter table public.adult_invitations
      add constraint adult_invitations_role_allowed
      check (role in ('owner', 'parent', 'caregiver', 'professional', 'viewer'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'adult_invitations_status_allowed'
  ) then
    alter table public.adult_invitations
      add constraint adult_invitations_status_allowed
      check (status in ('pending', 'accepted', 'revoked', 'expired'));
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'routine_overrides_type_allowed'
  ) then
    alter table public.routine_overrides
      add constraint routine_overrides_type_allowed
      check (override_type in (
        'changeTime',
        'pauseToday',
        'skipToday',
        'runningLate',
        'sick',
        'traveling'
      ));
  end if;
end $$;

alter table public.adult_invitations enable row level security;
alter table public.routine_overrides enable row level security;

create policy "family members can view invitations"
on public.adult_invitations for select
using (is_family_member(adult_invitations.family_id));

create policy "owners can manage invitations"
on public.adult_invitations for all
using (is_family_owner(adult_invitations.family_id))
with check (is_family_owner(adult_invitations.family_id));

create policy "family members can access routine overrides"
on public.routine_overrides for all
using (
  exists (
    select 1 from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routine_overrides.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routine_overrides.profile_id
    and family_members.user_id = auth.uid()
  )
);
