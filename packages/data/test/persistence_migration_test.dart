import 'package:habitar_data/data.dart';
import 'package:test/test.dart';

void main() {
  test('json to Drift plan covers every local collection', () {
    const collections = [
      LocalStoreCollections.users,
      LocalStoreCollections.families,
      LocalStoreCollections.childProfiles,
      LocalStoreCollections.teenProfiles,
      LocalStoreCollections.routines,
      LocalStoreCollections.routineSteps,
      LocalStoreCollections.routineSessions,
      LocalStoreCollections.habits,
      LocalStoreCollections.habitProgress,
      LocalStoreCollections.notificationPreferences,
      LocalStoreCollections.emotionCheckIns,
      LocalStoreCollections.supportRequests,
      LocalStoreCollections.storyProgress,
      LocalStoreCollections.wearableSnapshots,
      LocalStoreCollections.wearableCommands,
      LocalStoreCollections.authState,
      LocalStoreCollections.syncQueue,
    ];

    for (final collection in collections) {
      expect(jsonToDriftMigrationPlan.coversCollection(collection), isTrue);
    }
  });

  test('sync queue and auth state are local-only migration tables', () {
    final localOnly = jsonToDriftMigrationPlan.tables
        .where((table) => !table.syncable)
        .map((table) => table.collection);

    expect(localOnly, contains(LocalStoreCollections.syncQueue));
    expect(localOnly, contains(LocalStoreCollections.authState));
  });
}
