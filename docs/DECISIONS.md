# Product and Engineering Decisions

## Adult and child separation

Children and teens cannot create routines or habits. Adults, caregivers, teachers and professionals configure the plan.

## Multiadult model

The canonical relationship is:

`adult user -> family_members -> family -> child profile`

This allows several adults to access the same family and same child profile without duplicating the child.

Final family roles are `owner`, `parent`, `caregiver`, `professional` and `viewer`. Migration `0004` updates the original role constraint in place so earlier rows remain valid.

Invitations are accepted through the Supabase `accept_family_invitation` RPC. The app does not trust the client to insert a member and update an invitation as two separate writes. The RPC verifies the authenticated email, pending status and expiration, then creates or returns the member atomically.

We corrected `0004` directly because it had not been applied to the remote Supabase project yet. If a later environment has already applied an older version of `0004`, use a new corrective migration instead of replaying history.

## Routine edits

Editing a routine updates the base schedule and steps. "Adjust only today" creates a `routine_override` so the weekly routine remains unchanged.

Routine save still writes the routine and its steps as separate operations. This is acceptable for the internal test, but a future release should move create/update into a single transactional Supabase RPC so a partial network failure cannot leave a routine without all of its steps.

## Notifications

Android routine reminders are local notifications scheduled on the device for routine start and follow-up. They are cancelled when a routine is paused or completed from the app. Habitar does not yet ship FCM push, transactional email reminders, or native smartwatch notification delivery.

## Web

Flutter Web is enabled as the same product surface. Web should use the same auth and Supabase data as mobile when environment variables are configured.

## Wearables

Wear OS and watchOS are not treated as generic smartwatch support. Current code keeps contracts and UI readiness. Native companion targets still need a later implementation.

## PDF

Reports are generated inside the app with `pdf` and exported through `printing`. The PDF avoids comparison-based language and focuses on support, routines, autonomy and friction.
