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

When a new migration is added, apply it in Supabase before publishing a build that depends on the new table.
