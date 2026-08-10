-- Adds non-punitive time bank benefits for internal testing.
-- Rollback guidance: export time_bank_benefits before dropping this table.

create unique index if not exists routines_id_profile_id_idx
  on public.routines (id, profile_id);

create unique index if not exists habits_id_profile_id_idx
  on public.habits (id, profile_id);

create table if not exists public.time_bank_benefits (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  routine_id uuid references public.routines(id) on delete set null,
  habit_id uuid references public.habits(id) on delete set null,
  kind text not null default 'digitalTime',
  description text not null,
  minutes_earned integer not null check (minutes_earned > 0),
  minutes_used integer not null default 0,
  daily_limit_minutes integer check (
    daily_limit_minutes is null or daily_limit_minutes > 0
  ),
  expires_at timestamptz,
  accumulation_allowed boolean not null default true,
  status text not null default 'available',
  source_action text,
  idempotency_key text,
  approved_by_adult_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner_id uuid references auth.users(id) on delete set null,
  constraint time_bank_benefits_minutes_used_range
    check (minutes_used >= 0 and minutes_used <= minutes_earned),
  constraint time_bank_benefits_routine_profile_fk
    foreign key (routine_id, profile_id)
    references public.routines(id, profile_id),
  constraint time_bank_benefits_habit_profile_fk
    foreign key (habit_id, profile_id)
    references public.habits(id, profile_id)
);

comment on column public.time_bank_benefits.owner_id is
  'Legacy owner reference kept for app compatibility. Family access is enforced through profile_id.';

create unique index if not exists time_bank_benefits_idempotency_key_idx
  on public.time_bank_benefits (idempotency_key)
  where idempotency_key is not null;

alter table public.time_bank_benefits enable row level security;

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

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'time_bank_benefits_kind_allowed'
  ) then
    alter table public.time_bank_benefits
      add constraint time_bank_benefits_kind_allowed
      check (kind in ('digitalTime', 'appTime', 'activity', 'story', 'music', 'adultTime', 'custom', 'recognition'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'time_bank_benefits_status_allowed'
  ) then
    alter table public.time_bank_benefits
      add constraint time_bank_benefits_status_allowed
      check (status in ('available', 'pendingApproval', 'used', 'expired', 'corrected'));
  end if;
end $$;
