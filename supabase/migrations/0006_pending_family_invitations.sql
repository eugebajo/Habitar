-- Pending invitations visible to the authenticated invited adult.
-- Safe to apply after 0001 through 0005.

create or replace function public.pending_family_invitations_for_current_user()
returns table (
  id uuid,
  family_id uuid,
  family_name text,
  email text,
  role text,
  status text,
  invited_by_user_id uuid,
  accepted_by_user_id uuid,
  expires_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    adult_invitations.id,
    adult_invitations.family_id,
    families.name as family_name,
    adult_invitations.email,
    adult_invitations.role,
    adult_invitations.status,
    adult_invitations.invited_by_user_id,
    adult_invitations.accepted_by_user_id,
    adult_invitations.expires_at,
    adult_invitations.created_at,
    adult_invitations.updated_at
  from public.adult_invitations
  join public.families on families.id = adult_invitations.family_id
  where auth.uid() is not null
    and lower(adult_invitations.email) =
      lower(coalesce(auth.jwt() ->> 'email', ''))
    and adult_invitations.status = 'pending'
    and adult_invitations.expires_at > now()
  order by adult_invitations.created_at desc;
$$;

revoke all on function public.pending_family_invitations_for_current_user()
  from public;

grant execute on function public.pending_family_invitations_for_current_user()
  to authenticated;
