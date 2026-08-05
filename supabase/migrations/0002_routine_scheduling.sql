-- Adds programmable routine metadata without removing or rewriting existing data.
-- Rollback guidance: remove these columns only after exporting dependent routine records.

alter table public.routines add column if not exists weekdays integer[] not null default '{}';
alter table public.routines add column if not exists scheduled_hour integer;
alter table public.routines add column if not exists scheduled_minute integer;
alter table public.routines add column if not exists estimated_duration_minutes integer;
alter table public.routines add column if not exists lead_reminder_minutes integer not null default 10;
alter table public.routines add column if not exists repeat_policy text not null default 'weekly';
alter table public.routines add column if not exists responsible_adult_profile_id uuid;
alter table public.routines add column if not exists context_label text;
alter table public.routines add column if not exists minimum_version text;
alter table public.routines add column if not exists benefit_description text;
alter table public.routines add column if not exists max_reminder_count integer not null default 2;
alter table public.routines add column if not exists reminder_interval_minutes integer not null default 5;
alter table public.routines add column if not exists vibration_enabled boolean not null default true;
alter table public.routines add column if not exists sound_enabled boolean not null default false;
alter table public.routines add column if not exists silent_notification boolean not null default false;
alter table public.routines add column if not exists can_postpone boolean not null default true;
alter table public.routines add column if not exists can_request_help boolean not null default true;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'routines_scheduled_hour_range'
  ) then
    alter table public.routines
      add constraint routines_scheduled_hour_range
      check (scheduled_hour is null or scheduled_hour between 0 and 23);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'routines_scheduled_minute_range'
  ) then
    alter table public.routines
      add constraint routines_scheduled_minute_range
      check (scheduled_minute is null or scheduled_minute between 0 and 59);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'routines_repeat_policy_allowed'
  ) then
    alter table public.routines
      add constraint routines_repeat_policy_allowed
      check (repeat_policy in ('once', 'daily', 'weekly', 'weekdays', 'custom'));
  end if;
end $$;
