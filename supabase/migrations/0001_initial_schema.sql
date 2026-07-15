create extension if not exists "pgcrypto";

create type entity_status as enum ('active', 'paused', 'archived', 'deleted');
create type habit_status as enum ('proposed', 'new_habit', 'practicing', 'stable', 'paused', 'archived');
create type profile_kind as enum ('child', 'teen');

create table families (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  name text not null
);

create table family_members (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'caregiver', 'professional')),
  created_at timestamptz not null default now(),
  unique (family_id, user_id)
);

create table profiles (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  family_id uuid not null references families(id) on delete cascade,
  kind profile_kind not null,
  display_name text not null,
  age int not null check (age between 3 and 17),
  private_reflection_enabled boolean not null default true
);

create table routines (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  title text not null
);

create table routine_steps (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  routine_id uuid not null references routines(id) on delete cascade,
  title text not null,
  step_order int not null,
  estimated_minutes int,
  unique (routine_id, step_order)
);

create table routine_sessions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  routine_id uuid not null references routines(id) on delete cascade,
  active_step_index int not null default 0,
  session_status text not null check (session_status in ('running', 'paused', 'completed', 'postponed')),
  completed_step_ids uuid[] not null default '{}',
  skipped_step_ids uuid[] not null default '{}',
  extra_minutes_by_step_id jsonb not null default '{}'::jsonb,
  pause_reason text,
  help_requested boolean not null default false,
  postponed_until timestamptz
);

create table habits (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  habit_status habit_status not null default 'proposed',
  minimum_version text
);

create table habit_activations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  habit_id uuid not null references habits(id) on delete cascade,
  started_at timestamptz not null default now(),
  confirmed_override boolean not null default false
);

create table habit_progress (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  habit_id uuid not null references habits(id) on delete cascade,
  recorded_at timestamptz not null default now(),
  completed_minimum_version boolean not null default false,
  help_level int not null check (help_level between 0 and 5),
  ease int not null check (ease between 0 and 5),
  note text
);

create table notification_preferences (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  permission_status text not null check (permission_status in ('unknown', 'denied', 'granted')),
  intensity text not null check (intensity in ('quiet', 'visible', 'persistent_allowed', 'silent', 'wearable_only')),
  unique (profile_id)
);

create table emotion_check_ins (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  emotion text,
  energy_level int check (energy_level between 0 and 5),
  overload_level int check (overload_level between 0 and 5),
  needs_quiet boolean not null default false,
  needs_movement boolean not null default false,
  skipped boolean not null default false
);

create table support_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  kind text not null,
  note text
);

create table story_progress (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  profile_id uuid not null references profiles(id) on delete cascade,
  story_id text not null,
  is_favorite boolean not null default false,
  unique (profile_id, story_id)
);

create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner uuid not null references auth.users(id) on delete cascade,
  status entity_status not null default 'active',
  access_rules jsonb not null default '[]'::jsonb,
  actor_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  target_type text not null,
  target_id uuid
);

create or replace function is_family_member(target_family_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from family_members
    where family_members.family_id = target_family_id
    and family_members.user_id = auth.uid()
  );
$$;

create or replace function is_family_owner(target_family_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from family_members
    where family_members.family_id = target_family_id
    and family_members.user_id = auth.uid()
    and family_members.role = 'owner'
  );
$$;

alter table families enable row level security;
alter table family_members enable row level security;
alter table profiles enable row level security;
alter table routines enable row level security;
alter table routine_steps enable row level security;
alter table routine_sessions enable row level security;
alter table habits enable row level security;
alter table habit_activations enable row level security;
alter table habit_progress enable row level security;
alter table notification_preferences enable row level security;
alter table emotion_check_ins enable row level security;
alter table support_requests enable row level security;
alter table story_progress enable row level security;
alter table audit_logs enable row level security;

create policy "families are visible to members"
on families for select
using (is_family_member(families.id));

create policy "owners can create families"
on families for insert
with check (owner = auth.uid());

create policy "members are visible to same family"
on family_members for select
using (is_family_member(family_members.family_id));

create policy "owners can manage members"
on family_members for all
using (is_family_owner(family_members.family_id))
with check (
  exists (
    select 1 from families
    where families.id = family_members.family_id
    and families.owner = auth.uid()
  )
);

create policy "family scoped profiles"
on profiles for all
using (
  exists (
    select 1 from family_members
    where family_members.family_id = profiles.family_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped routines"
on routines for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = routines.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped routine steps"
on routine_steps for all
using (
  exists (
    select 1 from routines
    join profiles on profiles.id = routines.profile_id
    join family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_steps.routine_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped routine sessions"
on routine_sessions for all
using (
  exists (
    select 1 from routines
    join profiles on profiles.id = routines.profile_id
    join family_members on family_members.family_id = profiles.family_id
    where routines.id = routine_sessions.routine_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped habits"
on habits for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = habits.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped habit activations"
on habit_activations for all
using (
  exists (
    select 1 from habits
    join profiles on profiles.id = habits.profile_id
    join family_members on family_members.family_id = profiles.family_id
    where habits.id = habit_activations.habit_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped habit progress"
on habit_progress for all
using (
  exists (
    select 1 from habits
    join profiles on profiles.id = habits.profile_id
    join family_members on family_members.family_id = profiles.family_id
    where habits.id = habit_progress.habit_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped notification preferences"
on notification_preferences for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = notification_preferences.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped emotion check ins"
on emotion_check_ins for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = emotion_check_ins.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped support requests"
on support_requests for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = support_requests.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "family scoped story progress"
on story_progress for all
using (
  exists (
    select 1 from profiles
    join family_members on family_members.family_id = profiles.family_id
    where profiles.id = story_progress.profile_id
    and family_members.user_id = auth.uid()
  )
)
with check (owner = auth.uid());

create policy "own audit logs"
on audit_logs for select
using (owner = auth.uid());

create policy "insert own audit logs"
on audit_logs for insert
with check (owner = auth.uid() and actor_id = auth.uid());
