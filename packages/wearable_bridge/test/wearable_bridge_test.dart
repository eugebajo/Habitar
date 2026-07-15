import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:habitar_wearable_bridge/wearable_bridge.dart';
import 'package:test/test.dart';

void main() {
  test('maps routine session into a compact wearable snapshot', () {
    final now = DateTime(2026);
    final session = RoutineEngine().start(
      sessionId: 'session-1',
      routine: Routine(
        metadata: EntityMetadata(id: 'routine-1', createdAt: now, updatedAt: now, ownerId: 'profile-1'),
        profileId: 'profile-1',
        title: 'Salida',
      ),
      steps: [
        _step('1', 'Mochila', 1),
        _step('2', 'Zapatos', 2),
        _step('3', 'Puerta', 3),
      ],
      now: now,
    );

    final snapshot = const WearableSnapshotMapper().fromRoutineSession(session);

    expect(snapshot.currentStepTitle, 'Mochila');
    expect(snapshot.nextStepTitle, 'Zapatos');
    expect(snapshot.isActionable, isTrue);
  });

  test('plans distinct transports for watchOS and Wear OS', () {
    const planner = WearablePlatformPlanner();

    expect(planner.capabilitiesFor(WearablePlatform.watchOS).transports, contains(WearableTransport.watchConnectivity));
    expect(planner.capabilitiesFor(WearablePlatform.wearOS).transports, contains(WearableTransport.wearDataLayer));
  });
}

RoutineStep _step(String id, String title, int order) {
  final now = DateTime(2026);
  return RoutineStep(
    metadata: EntityMetadata(id: id, createdAt: now, updatedAt: now, ownerId: 'profile-1'),
    routineId: 'routine-1',
    title: title,
    order: order,
    estimatedMinutes: 3,
  );
}
