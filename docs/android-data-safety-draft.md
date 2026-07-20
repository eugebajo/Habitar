# Android Data safety draft

This is a product/engineering draft, not legal advice. It must be reviewed
against the final production implementation before Play Store submission.

## Data the app is expected to collect

- Account data:
  - Email
  - Adult display name
  - Authentication identifiers
- Family/profile data:
  - Family name
  - Child/adolescent display name
  - Age
  - Profile type
- App activity:
  - Routines created
  - Routine steps
  - Habit titles
  - Habit progress
  - Story progress
  - Notification preferences
- Optional wellbeing data:
  - Emotion check-ins
  - Support requests

## Purpose

- Account creation and login.
- Family and profile management.
- Routine and habit tracking.
- Progress summaries.
- Optional wellbeing support.
- Sync and backup through Supabase.

## Sharing

Expected: no sale of user data.

Potential processors/subprocessors:

- Supabase for authentication, database, and sync.
- Store platform services as required by Google Play.

## Security practices

Expected:

- Data encrypted in transit.
- Supabase Row Level Security for production database tables.
- Local data stored on the device.
- Adult space protected by PIN/confirmation flow in the app.

## Questions to answer before Play submission

- What exact data is persisted remotely in production Supabase?
- Is wellbeing/check-in data synced or local-only?
- Is any analytics SDK enabled?
- Are crash reports enabled?
- Are notifications native or simulated at launch?
- Is the app directed to children under Google Play Families policy, or is it
  a caregiver tool with child/adolescent profile modes?
