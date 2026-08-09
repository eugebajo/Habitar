-- Family invitations and one-day routine overrides.
-- Safe to apply after 0001, 0002 and 0003.
-- This migration is non-destructive and keeps existing family_members rows.

alter table public.family_members
  drop constraint if exists family_members_role_check;

alter table public.family_members
  add constraint family_members_role_check
  check (role in ('owner', 'parent', 'caregiver', 'professional', 'viewer'));

create table if not exists public.adult_invitations (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  email text not null,
  role text not null default 'viewer',
  status text not null default 'pending',
  invited_by_user_id uuid not null references auth.users(id) on delete cascade,
  accepted_by_user_id uuid references auth.users(id) on delete set null,
  expires_at timestamptz not null default (now() + interval '14 days'),
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
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (routine_id, override_date)
);

alter table public.adult_invitations
  drop constraint if exists adult_invitations_role_allowed;

alter table public.adult_invitations
  add constraint adult_invitations_role_allowed
  check (role in ('parent', 'caregiver', 'professional', 'viewer'));

alter table public.adult_invitations
  drop constraint if exists adult_invitations_status_allowed;

alter table public.adult_invitations
  add constraint adult_invitations_status_allowed
  check (status in ('pending', 'accepted', 'revoked', 'expired'));

alter table public.routine_overrides
  drop constraint if exists routine_overrides_type_allowed;

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

alter table public.routine_overrides
  drop constraint if exists routine_overrides_time_valid;

alter table public.routine_overrides
  add constraint routine_overrides_time_valid
  check (
    (start_hour is null and start_minute is null)
    or (
      start_hour between 0 and 23
      and start_minute between 0 and 59
    )
  );

alter table public.routine_overrides
  drop constraint if exists routine_overrides_profile_matches_routine;

create unique index if not exists routines_id_profile_id_idx
  on public.routines (id, profile_id);

alter table public.routine_overrides
  add constraint routine_overrides_profile_matches_routine
  foreign key (routine_id, profile_id)
  references public.routines(id, profile_id)
  on delete cascade;

create unique index if not exists adult_invitations_pending_email_idx
  on public.adult_invitations (family_id, lower(email))
  where status = 'pending';

create index if not exists adult_invitations_email_status_idx
  on public.adult_invitations (lower(email), status);

create index if not exists routine_overrides_profile_date_idx
  on public.routine_overrides (profile_id, override_date);

alter table public.adult_invitations enable row level security;
alter table public.routine_overrides enable row level security;

drop policy if exists "family scoped routines"
  on public.routines;
drop policy if exists "family members can view routines"
  on public.routines;
drop policy if exists "authorized adults can manage routines"
  on public.routines;

create policy "family members can view routines"
on public.routines for select
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routines.profile_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage routines"
on public.routines for all
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routines.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routines.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family scoped routine steps"
  on public.routine_steps;
drop policy if exists "family members can view routine steps"
  on public.routine_steps;
drop policy if exists "authorized adults can manage routine steps"
  on public.routine_steps;

create policy "family members can view routine steps"
on public.routine_steps for select
using (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_steps.routine_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage routine steps"
on public.routine_steps for all
using (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_steps.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  exists (
    select 1
    from public.routines
    join public.profiles on profiles.id = routines.profile_id
    join public.family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_steps.routine_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

drop policy if exists "family members can view invitations"
  on public.adult_invitations;
drop policy if exists "owners can manage invitations"
  on public.adult_invitations;
drop policy if exists "invited adults can view own pending invitations"
  on public.adult_invitations;
drop policy if exists "owners and parents can create invitations"
  on public.adult_invitations;
drop policy if exists "owners and parents can revoke invitations"
  on public.adult_invitations;

create policy "family members can view invitations"
on public.adult_invitations for select
using (is_family_member(adult_invitations.family_id));

create policy "invited adults can view own pending invitations"
on public.adult_invitations for select
using (
  status = 'pending'
  and expires_at > now()
  and lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
);

create policy "owners and parents can create invitations"
on public.adult_invitations for insert
with check (
  exists (
    select 1 from public.family_members
    where family_members.family_id = adult_invitations.family_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent')
  )
);

drop policy if exists "family members can access routine overrides"
  on public.routine_overrides;
drop policy if exists "authorized adults can manage routine overrides"
  on public.routine_overrides;

create policy "family members can access routine overrides"
on public.routine_overrides for select
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routine_overrides.profile_id
    and family_members.user_id = auth.uid()
  )
);

create policy "authorized adults can manage routine overrides"
on public.routine_overrides for all
using (
  exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routine_overrides.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
)
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from public.profiles
    join public.family_members on family_members.family_id = profiles.family_id
    where profiles.id = routine_overrides.profile_id
    and family_members.user_id = auth.uid()
    and family_members.role in ('owner', 'parent', 'caregiver')
  )
);

create or replace function public.accept_family_invitation(
  target_invitation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid;
  current_email text;
  invitation_row public.adult_invitations%rowtype;
  member_row public.family_members%rowtype;
begin
  current_user_id := auth.uid();
  current_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if current_user_id is null or current_email = '' then
    raise exception 'AUTH_REQUIRED';
  end if;

  select *
  into invitation_row
  from public.adult_invitations
  where id = target_invitation_id
  for update;

  if not found then
    raise exception 'INVITATION_NOT_FOUND';
  end if;

  if lower(invitation_row.email) <> current_email then
    raise exception 'INVITATION_EMAIL_MISMATCH';
  end if;

  if invitation_row.status <> 'pending' then
    select *
    into member_row
    from public.family_members
    where family_id = invitation_row.family_id
    and user_id = current_user_id
    limit 1;

    if found then
      return to_jsonb(member_row);
    end if;

    raise exception 'INVITATION_NOT_PENDING';
  end if;

  if invitation_row.expires_at <= now() then
    update public.adult_invitations
    set status = 'expired',
        updated_at = now()
    where id = invitation_row.id;
    raise exception 'INVITATION_EXPIRED';
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (invitation_row.family_id, current_user_id, invitation_row.role)
  on conflict (family_id, user_id) do nothing
  returning *
  into member_row;

  if not found then
    select *
    into member_row
    from public.family_members
    where family_id = invitation_row.family_id
    and user_id = current_user_id
    limit 1;
  end if;

  update public.adult_invitations
  set status = 'accepted',
      accepted_by_user_id = current_user_id,
      updated_at = now()
  where id = invitation_row.id;

  return to_jsonb(member_row);
end;
$$;

grant execute on function public.accept_family_invitation(uuid)
  to authenticated;
