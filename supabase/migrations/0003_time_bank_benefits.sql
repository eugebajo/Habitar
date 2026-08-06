-- Adds non-punitive time bank benefits for internal testing.
-- Rollback guidance: export time_bank_benefits before dropping this table.

create table if not exists public.time_bank_benefits (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  routine_id uuid,
  habit_id uuid,
  kind text not null default 'digitalTime',
  description text not null,
  minutes_earned integer not null check (minutes_earned > 0),
  minutes_used integer not null default 0 check (minutes_used >= 0),
  daily_limit_minutes integer,
  expires_at timestamptz,
  accumulation_allowed boolean not null default true,
  status text not null default 'available',
  source_action text,
  idempotency_key text,
  approved_by_adult_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  owner_id uuid
);

create unique index if not exists time_bank_benefits_idempotency_key_idx
  on public.time_bank_benefits (idempotency_key)
  where idempotency_key is not null;

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
