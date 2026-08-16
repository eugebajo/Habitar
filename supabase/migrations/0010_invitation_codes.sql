-- Invitation codes for a second adult to join a family by pasting a code
-- shared over WhatsApp (no email delivery, no SMTP, no Edge Functions).
--
-- Additive and reversible. Safe to apply after 0001-0009. Does not touch
-- 0008 or 0009, and does not modify the existing email-id based
-- accept_family_invitation / revoke_family_invitation functions from 0004 -
-- both flows keep working side by side (invite_code_hash is null for
-- invitations created the old way).
--
-- PRE-FLIGHT CHECKS (run manually, read-only, before applying):
--
-- 1) select extnamespace::regnamespace from pg_extension where extname = 'pgcrypto';
--    Verified against this project: pgcrypto lives in the `extensions`
--    schema, not `public` (0001_initial_schema.sql's unqualified `create
--    extension if not exists "pgcrypto"` turned out not to control this -
--    the project already had it provisioned in `extensions`). This
--    migration calls `extensions.digest(...)` for the code hash
--    accordingly. If you ever run this against a different project, redo
--    this check first - if it returns something other than `extensions`,
--    replace `extensions.digest` with that schema everywhere in this file
--    before applying.
--
-- 2) select conname, pg_get_constraintdef(oid)
--    from pg_constraint
--    where conrelid = 'public.adult_invitations'::regclass
--      and contype = 'c';
--    Confirms the current check constraints on adult_invitations. Per
--    0004_family_invitations_and_routine_overrides.sql lines 48-53, the
--    status check is added by name via a separate `alter table ... add
--    constraint adult_invitations_status_allowed check (...)` - the
--    `create table` a few lines above it has no inline check on `status`
--    at all - so a clean apply of 0001-0009 names it
--    `adult_invitations_status_allowed`, which is what this migration drops
--    below. The drop is also done dynamically (by discovering whichever
--    check constraint actually covers the `status` column, whatever it's
--    named) so this still works even if the live database's history ever
--    diverged from these migration files; if it finds more than one such
--    constraint it raises an exception instead of guessing, so run query 2
--    above first if you want to see exactly what's there before applying.
--
-- ROLLBACK (manual, commented at the end of this file).

begin;

-- ---------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------

alter table public.adult_invitations
  add column if not exists invite_code_hash text,
  add column if not exists accepted_at timestamptz,
  add column if not exists canceled_at timestamptz;

-- Only invitations created through create_family_invitation_with_code get a
-- hash; invitations from the existing email-id flow leave it null, and a
-- plain `unique` column would already allow multiple nulls, but a partial
-- index says exactly what we mean and matches this file's existing style
-- (see adult_invitations_pending_email_idx in 0004).
create unique index if not exists adult_invitations_invite_code_hash_idx
  on public.adult_invitations (invite_code_hash)
  where invite_code_hash is not null;

-- Robust drop: discover whichever check constraint actually covers the
-- `status` column, by name, and drop that - instead of assuming it's named
-- adult_invitations_status_allowed (which pre-flight check 2 above
-- confirms is the name after a clean 0001-0009 apply, but this doesn't
-- depend on that being true). No client input is involved here, only
-- system catalog data, so the dynamic SQL below carries no injection risk.
do $$
declare
  status_constraint_names text[];
begin
  select array_agg(pg_constraint.conname)
  into status_constraint_names
  from pg_constraint
  join pg_attribute
    on pg_attribute.attrelid = pg_constraint.conrelid
   and pg_attribute.attnum = any (pg_constraint.conkey)
  where pg_constraint.conrelid = 'public.adult_invitations'::regclass
    and pg_constraint.contype = 'c'
    and pg_attribute.attname = 'status';

  if status_constraint_names is null then
    -- No existing check constraint on status; nothing to drop.
    null;
  elsif array_length(status_constraint_names, 1) > 1 then
    raise exception
      'Found more than one check constraint on adult_invitations.status (%), refusing to guess which to drop. Resolve manually before re-running this migration.',
      array_to_string(status_constraint_names, ', ');
  else
    execute format(
      'alter table public.adult_invitations drop constraint %I',
      status_constraint_names[1]
    );
  end if;
end $$;

alter table public.adult_invitations
  add constraint adult_invitations_status_allowed
  check (status in ('pending', 'accepted', 'revoked', 'expired', 'canceled'));

-- ---------------------------------------------------------------------
-- create_family_invitation_with_code
-- ---------------------------------------------------------------------
--
-- SECURITY DEFINER is required because RLS alone cannot: (a) generate the
-- code and store only its hash while returning the plaintext exactly once,
-- (b) atomically lazy-expire a stale pending invitation for the same
-- family+email so a legitimately re-sent invite doesn't collide with the
-- partial unique index, and (c) compare the target email against
-- auth.jwt() ->> 'email' to reject self-invitation before any row is
-- written. target_family_id is accepted as an input (the function needs to
-- know which family), but it is never trusted as authority: every write is
-- gated by an explicit lookup of the caller's own row in family_members via
-- auth.uid(), not by anything the client claims.
create or replace function public.create_family_invitation_with_code(
  target_family_id uuid,
  target_email text,
  target_role text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  current_email text;
  normalized_email text;
  raw_code text;
  code_hash text;
  invitation_row public.adult_invitations%rowtype;
begin
  current_user_id := auth.uid();
  current_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  normalized_email := lower(trim(coalesce(target_email, '')));

  if normalized_email = '' or position('@' in normalized_email) = 0
     or length(normalized_email) > 320 then
    raise exception 'INVITATION_EMAIL_INVALID';
  end if;

  if target_role is null
     or target_role not in ('parent', 'caregiver', 'professional', 'viewer') then
    raise exception 'INVITATION_ROLE_INVALID';
  end if;

  if normalized_email = current_email then
    raise exception 'INVITATION_SELF_FORBIDDEN';
  end if;

  if not exists (
    select 1
    from public.family_members
    where family_members.family_id = target_family_id
    and family_members.user_id = current_user_id
    and family_members.role in ('owner', 'parent')
  ) then
    raise exception 'INVITATION_CREATE_FORBIDDEN';
  end if;

  -- Lazily expire a stale pending invitation for this family+email so it
  -- doesn't collide with adult_invitations_pending_email_idx below.
  update public.adult_invitations
  set status = 'expired',
      updated_at = now()
  where family_id = target_family_id
    and lower(email) = normalized_email
    and status = 'pending'
    and expires_at <= now();

  if exists (
    select 1
    from public.adult_invitations
    where family_id = target_family_id
    and lower(email) = normalized_email
    and status = 'pending'
  ) then
    raise exception 'INVITATION_ALREADY_PENDING';
  end if;

  -- A v4 UUID is exactly 128 bits of randomness from pg_catalog (no
  -- extension needed); stripping the dashes gives a 32-char hex code.
  raw_code := replace(gen_random_uuid()::text, '-', '');
  code_hash := encode(extensions.digest(raw_code, 'sha256'), 'hex');

  begin
    insert into public.adult_invitations (
      family_id,
      email,
      role,
      status,
      invited_by_user_id,
      invite_code_hash,
      expires_at
    )
    values (
      target_family_id,
      normalized_email,
      target_role,
      'pending',
      current_user_id,
      code_hash,
      now() + interval '7 days'
    )
    returning * into invitation_row;
  exception
    when unique_violation then
      raise exception 'INVITATION_ALREADY_PENDING';
  end;

  return jsonb_build_object(
    'invitation_id', invitation_row.id,
    'family_id', invitation_row.family_id,
    'email', invitation_row.email,
    'role', invitation_row.role,
    'expires_at', invitation_row.expires_at,
    'invite_code', raw_code
  );
end;
$$;

revoke all on function public.create_family_invitation_with_code(uuid, text, text)
  from public, anon;

grant execute on function public.create_family_invitation_with_code(uuid, text, text)
  to authenticated;

-- ---------------------------------------------------------------------
-- accept_family_invitation_by_code
-- ---------------------------------------------------------------------
--
-- SECURITY DEFINER is required because the caller has to be able to look up
-- an invitation by code hash before they are (or ever become) a member of
-- that family - existing adult_invitations SELECT policies only cover
-- family members and invitations addressed to the caller's own email, not
-- an anonymous-until-verified code lookup. It also performs the one-family-
-- per-adult transition (leaving any previous family, joining the new one)
-- atomically, which a family_members RLS policy cannot express as a single
-- guarded write. invitation_code is the only input; the family and role to
-- apply come from the row the hash resolves to, never from the client.
--
-- Invalid code, expired, already used, canceled AND email mismatch all
-- return the exact same generic error. These codes travel over WhatsApp -
-- forwarded, screenshotted, left sitting in group chats - so a code can
-- easily end up in front of someone it wasn't meant for. If a distinct
-- "this code is for another email" message existed, whoever holds a
-- forwarded/misdirected code would learn that a specific email address has
-- a pending invitation to this family, i.e. that a specific child has an
-- account on Habitar. That oracle is not worth a more specific error
-- message, so email mismatch is folded into the same generic bucket as an
-- invalid/expired/used/canceled code, and so is a revoked invitation (the
-- older email-id flow's terminal status), for the same reason. The
-- accept_family_invitation function in 0004 raises a distinct
-- INVITATION_EMAIL_MISMATCH for this case; that predates this design
-- decision and is not a reason to repeat it here.
create or replace function public.accept_family_invitation_by_code(
  invitation_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  current_email text;
  normalized_code text;
  code_hash text;
  invitation_row public.adult_invitations%rowtype;
begin
  current_user_id := auth.uid();
  current_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  if current_user_id is null or current_email = '' then
    raise exception 'AUTH_REQUIRED';
  end if;

  normalized_code := lower(regexp_replace(coalesce(invitation_code, ''), '\s', '', 'g'));

  if normalized_code = '' then
    raise exception 'INVITATION_CODE_INVALID_OR_EXPIRED';
  end if;

  code_hash := encode(extensions.digest(normalized_code, 'sha256'), 'hex');

  select *
  into invitation_row
  from public.adult_invitations
  where invite_code_hash = code_hash
  for update;

  if not found then
    raise exception 'INVITATION_CODE_INVALID_OR_EXPIRED';
  end if;

  if invitation_row.status = 'pending' and invitation_row.expires_at <= now() then
    update public.adult_invitations
    set status = 'expired',
        updated_at = now()
    where id = invitation_row.id;

    raise exception 'INVITATION_CODE_INVALID_OR_EXPIRED';
  end if;

  -- Covers accepted, canceled, revoked and (already-lazily-expired) expired.
  if invitation_row.status <> 'pending' then
    raise exception 'INVITATION_CODE_INVALID_OR_EXPIRED';
  end if;

  if lower(invitation_row.email) <> current_email then
    raise exception 'INVITATION_CODE_INVALID_OR_EXPIRED';
  end if;

  -- One family per adult: leave every other family membership before
  -- joining this one. Abandoned families are intentionally left orphaned
  -- (not deleted) so we never trigger cascade deletes on their data.
  delete from public.family_members
  where user_id = current_user_id
  and family_id <> invitation_row.family_id;

  insert into public.family_members (family_id, user_id, role)
  values (invitation_row.family_id, current_user_id, invitation_row.role)
  on conflict (family_id, user_id) do nothing;

  update public.adult_invitations
  set status = 'accepted',
      accepted_at = now(),
      accepted_by_user_id = current_user_id,
      updated_at = now()
  where id = invitation_row.id;

  return jsonb_build_object(
    'status', 'accepted',
    'family_id', invitation_row.family_id,
    'role', invitation_row.role
  );
end;
$$;

revoke all on function public.accept_family_invitation_by_code(text)
  from public, anon;

grant execute on function public.accept_family_invitation_by_code(text)
  to authenticated;

-- ---------------------------------------------------------------------
-- cancel_family_invitation
-- ---------------------------------------------------------------------
--
-- SECURITY DEFINER for the same reason as revoke_family_invitation in
-- 0004: the authorization check (owner/parent of the invitation's family)
-- has to run against the invitation's own family_id, which the caller
-- looks up by target_invitation_id alone - not something a single RLS
-- using()/with check() clause on adult_invitations can express as a
-- logical (not physical) delete with this shape. Logical cancellation
-- only: no delete.
create or replace function public.cancel_family_invitation(
  target_invitation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  invitation_row public.adult_invitations%rowtype;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
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

  if not exists (
    select 1
    from public.family_members
    where family_members.family_id = invitation_row.family_id
    and family_members.user_id = current_user_id
    and family_members.role in ('owner', 'parent')
  ) then
    raise exception 'INVITATION_CANCEL_FORBIDDEN';
  end if;

  if invitation_row.status <> 'pending' then
    raise exception 'INVITATION_NOT_PENDING';
  end if;

  update public.adult_invitations
  set status = 'canceled',
      canceled_at = now(),
      updated_at = now()
  where id = invitation_row.id
  returning *
  into invitation_row;

  return jsonb_build_object(
    'status', 'canceled',
    'invitation_id', invitation_row.id
  );
end;
$$;

revoke all on function public.cancel_family_invitation(uuid)
  from public, anon;

grant execute on function public.cancel_family_invitation(uuid)
  to authenticated;

commit;

-- ---------------------------------------------------------------------
-- ROLLBACK (manual - run only if this migration must be reverted)
-- ---------------------------------------------------------------------
--
-- begin;
--
-- revoke all on function public.cancel_family_invitation(uuid)
--   from authenticated;
-- drop function if exists public.cancel_family_invitation(uuid);
--
-- revoke all on function public.accept_family_invitation_by_code(text)
--   from authenticated;
-- drop function if exists public.accept_family_invitation_by_code(text);
--
-- revoke all on function public.create_family_invitation_with_code(uuid, text, text)
--   from authenticated;
-- drop function if exists public.create_family_invitation_with_code(uuid, text, text);
--
-- drop index if exists public.adult_invitations_invite_code_hash_idx;
--
-- alter table public.adult_invitations
--   drop constraint if exists adult_invitations_status_allowed;
-- alter table public.adult_invitations
--   add constraint adult_invitations_status_allowed
--   check (status in ('pending', 'accepted', 'revoked', 'expired'));
-- -- NOTE: run this only after confirming no row has status = 'canceled',
-- -- otherwise the constraint re-add above will fail. Either update those
-- -- rows first (e.g. back to 'revoked') or drop the constraint entirely.
--
-- alter table public.adult_invitations
--   drop column if exists invite_code_hash,
--   drop column if exists accepted_at,
--   drop column if exists canceled_at;
--
-- commit;
