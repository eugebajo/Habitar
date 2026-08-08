# Product and Engineering Decisions

## Adult and child separation

Children and teens cannot create routines or habits. Adults, caregivers, teachers and professionals configure the plan.

## Multiadult model

The canonical relationship is:

`adult user -> family_members -> family -> child profile`

This allows several adults to access the same family and same child profile without duplicating the child.

## Routine edits

Editing a routine updates the base schedule and steps. "Adjust only today" creates a `routine_override` so the weekly routine remains unchanged.

## Web

Flutter Web is enabled as the same product surface. Web should use the same auth and Supabase data as mobile when environment variables are configured.

## Wearables

Wear OS and watchOS are not treated as generic smartwatch support. Current code keeps contracts and UI readiness. Native companion targets still need a later implementation.

## PDF

Reports are generated inside the app with `pdf` and exported through `printing`. The PDF avoids comparison-based language and focuses on support, routines, autonomy and friction.
