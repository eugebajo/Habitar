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

Release rule: before generating a new AAB, run `flutter analyze`, `flutter test`, web build and Android appbundle build from the repository root.
