# Habitar Architecture

Habitar is a Flutter monorepo organized in layers:

- `apps/mobile`: Flutter app for Android, iOS and web preview.
- `packages/domain`: entities, value objects and business enums.
- `packages/application`: use cases, service classes and repository contracts.
- `packages/data`: in-memory, local SQLite/JSON and Supabase repositories.
- `packages/design_system`: shared visual language, tokens and reusable widgets.
- `packages/notifications`: notification preferences and routine signal planning.
- `packages/wearable_bridge`: wearable snapshots and quick-action contracts.
- `supabase/migrations`: remote schema and RLS policies.

The app must keep children and teens in separated experiences. Adults create and manage routines, habits, rewards, family members and reports. Children only execute assigned routines and request help, pause or more time.

Data access is always routed through application repository contracts. UI screens must not call Supabase directly.

Family sharing is modeled as `adult user -> family_members -> family -> child profile`. Several adults can belong to the same family and see the same child profile without duplication. Roles are enforced in the database through RLS and repository-level validation for local stores.

Adult invitation acceptance is intentionally server-side. Supabase uses the `accept_family_invitation` RPC so the authenticated email, target invitation, member creation and invitation status update are validated in one transaction.

Routine "adjust only today" is stored as `routine_overrides`; it does not mutate the recurring routine. Overrides are scoped to the profile family and manageable only by authorized adult roles.

Release rule: before generating a new AAB, run `flutter analyze`, `flutter test`, web build and Android appbundle build from the repository root.
