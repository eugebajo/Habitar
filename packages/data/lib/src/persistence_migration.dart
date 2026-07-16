import 'local_store.dart';

enum PersistenceBackend { jsonFile, driftSqlite }

class DriftTablePlan {
  const DriftTablePlan({
    required this.collection,
    required this.tableName,
    required this.primaryKey,
    required this.syncable,
  });

  final String collection;
  final String tableName;
  final String primaryKey;
  final bool syncable;
}

class PersistenceMigrationPlan {
  const PersistenceMigrationPlan({
    required this.from,
    required this.to,
    required this.tables,
  });

  final PersistenceBackend from;
  final PersistenceBackend to;
  final List<DriftTablePlan> tables;

  Iterable<DriftTablePlan> get syncableTables =>
      tables.where((table) => table.syncable);

  bool coversCollection(String collection) {
    return tables.any((table) => table.collection == collection);
  }
}

const jsonToDriftMigrationPlan = PersistenceMigrationPlan(
  from: PersistenceBackend.jsonFile,
  to: PersistenceBackend.driftSqlite,
  tables: [
    DriftTablePlan(
        collection: LocalStoreCollections.users,
        tableName: 'users',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.families,
        tableName: 'families',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.childProfiles,
        tableName: 'child_profiles',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.teenProfiles,
        tableName: 'teen_profiles',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.routines,
        tableName: 'routines',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.routineSteps,
        tableName: 'routine_steps',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.routineSessions,
        tableName: 'routine_sessions',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.habits,
        tableName: 'habits',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.habitProgress,
        tableName: 'habit_progress',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.notificationPreferences,
        tableName: 'notification_preferences',
        primaryKey: 'profile_id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.emotionCheckIns,
        tableName: 'emotion_check_ins',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.supportRequests,
        tableName: 'support_requests',
        primaryKey: 'id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.storyProgress,
        tableName: 'story_progress',
        primaryKey: 'profile_story_id',
        syncable: true),
    DriftTablePlan(
        collection: LocalStoreCollections.wearableSnapshots,
        tableName: 'wearable_snapshots',
        primaryKey: 'platform',
        syncable: false),
    DriftTablePlan(
        collection: LocalStoreCollections.wearableCommands,
        tableName: 'wearable_commands',
        primaryKey: 'id',
        syncable: false),
    DriftTablePlan(
        collection: LocalStoreCollections.authState,
        tableName: 'auth_state',
        primaryKey: 'key',
        syncable: false),
    DriftTablePlan(
        collection: LocalStoreCollections.syncQueue,
        tableName: 'sync_queue',
        primaryKey: 'id',
        syncable: false),
  ],
);
