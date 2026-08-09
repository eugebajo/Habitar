# Supabase Setup

Required public configuration:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Never commit private service keys. The publishable/anon key can be used by the app because Row Level Security protects the data.

Current remote tables covered by migrations include:

- `families`
- `family_members`
- `adult_invitations`
- `profiles`
- `routines`
- `routine_steps`
- `routine_overrides`

Important relationships:

- An authenticated adult belongs to a family through `family_members`.
- A family can have many child or teen profiles.
- A child profile can have many routines and routine steps.
- A routine can have one override for a date, used for "adjust only today".
- Adult invitations invite another adult account into the same family without duplicating child profiles.

## Family roles

The canonical `family_members.role` values are:

- `owner`: full control.
- `parent`: child, routine, progress, reward, device and invitation management.
- `caregiver`: routine support and day-to-day follow-up.
- `professional`: progress/report-oriented access.
- `viewer`: read-only access.

Migration `0004_family_invitations_and_routine_overrides.sql` updates the original `family_members` check constraint without recreating the table, so existing `owner`, `caregiver` and `professional` rows remain valid.

## Invitations

`adult_invitations` stores the normalized email, family, target role, status, inviter, optional accepted user and `expires_at`.

Invitation acceptance is handled by the Supabase RPC:

`accept_family_invitation(target_invitation_id uuid)`

The RPC runs as `SECURITY DEFINER`, uses `auth.uid()` and the authenticated JWT email, validates that the invitation is pending, not expired and addressed to the current email, creates the `family_members` row atomically, then marks the invitation as accepted. The client does not choose the accepted user id and does not perform separate member insert/update operations.

Owners and parents can create invitations. Invited adults can only read their own pending invitation. Direct invitation acceptance must go through the RPC.

## Routine overrides

`routine_overrides` stores one override per routine and date. It references both `routine_id` and `profile_id`, validates time fields, and is restricted by RLS to adults in the same family. Owners, parents and caregivers can manage overrides; professional and viewer roles can read family-scoped data but cannot manage overrides.

When a new migration is added, apply it in Supabase before publishing a build that depends on the new table.
