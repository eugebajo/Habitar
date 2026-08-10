-- Secure initial family bootstrap for confirmed adult accounts.
-- Applies after 0001-0004. Does not relax RLS policies.

create or replace function public.create_initial_family(family_name text)
returns public.families
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid;
  normalized_name text;
  family_row public.families%rowtype;
begin
  current_user_id := auth.uid();
  normalized_name := trim(coalesce(family_name, ''));

  if current_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if normalized_name = '' then
    raise exception 'FAMILY_NAME_REQUIRED';
  end if;

  if length(normalized_name) > 120 then
    raise exception 'FAMILY_NAME_TOO_LONG';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext(current_user_id::text)
  );

  select families.*
  into family_row
  from public.families
  join public.family_members
    on family_members.family_id = families.id
  where families.owner = current_user_id
    and family_members.user_id = current_user_id
    and family_members.role = 'owner'
    and families.status <> 'deleted'
  order by families.created_at
  limit 1;

  if found then
    return family_row;
  end if;

  select *
  into family_row
  from public.families
  where owner = current_user_id
    and status <> 'deleted'
  order by created_at
  limit 1
  for update;

  if not found then
    insert into public.families (owner, name)
    values (current_user_id, normalized_name)
    returning *
    into family_row;
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (family_row.id, current_user_id, 'owner')
  on conflict (family_id, user_id) do update
  set role = 'owner'
  where public.family_members.user_id = current_user_id;

  return family_row;
end;
$$;

revoke all on function public.create_initial_family(text)
  from public;
revoke all on function public.create_initial_family(text)
  from anon;

grant execute on function public.create_initial_family(text)
  to authenticated;
