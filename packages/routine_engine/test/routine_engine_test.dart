import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:test/test.dart';

void main() {
  group('RoutineEngine', () {
    test('starts only routines with at least three steps', () {
      final engine = RoutineEngine();

      expect(
        () => engine.start(sessionId: 's1', routine: _routine(), steps: [_step('1', 1), _step('2', 2)], now: DateTime(2026)),
        throwsArgumentError,
      );
    });

    test('keeps progress when a session is paused and resumed', () {
      final engine = RoutineEngine();
      final now = DateTime(2026);
      final started = engine.start(
        sessionId: 's1',
        routine: _routine(),
        steps: [_step('1', 1), _step('2', 2), _step('3', 3)],
        now: now,
      );

      final afterFirstStep = engine.completeActiveStep(started, now.add(const Duration(minutes: 2)));
      final paused = engine.pause(afterFirstStep, reason: RoutinePauseReason.sensory, now: now.add(const Duration(minutes: 3)));
      final resumed = engine.resume(paused, now.add(const Duration(minutes: 5)));

      expect(resumed.completedStepIds, ['1']);
      expect(resumed.activeStep?.metadata.id, '2');
      expect(resumed.status, RoutineSessionStatus.running);
    });

    test('adds more time without moving the active step', () {
      final engine = RoutineEngine();
      final session = engine.start(
        sessionId: 's1',
        routine: _routine(),
        steps: [_step('1', 1), _step('2', 2), _step('3', 3)],
        now: DateTime(2026),
      );

      final updated = engine.requestMoreTime(session, minutes: 5, now: DateTime(2026, 1, 1, 8, 5));

      expect(updated.activeStep?.metadata.id, '1');
      expect(updated.extraMinutesByStepId['1'], 5);
    });

    test('skipping a step still moves the visual progress forward', () {
      final engine = RoutineEngine();
      final session = engine.start(
        sessionId: 's1',
        routine: _routine(),
        steps: [_step('1', 1), _step('2', 2), _step('3', 3)],
        now: DateTime(2026),
      );

      final updated = engine.skipActiveStep(session, now: DateTime(2026, 1, 1, 8, 5));

      expect(updated.activeStep?.metadata.id, '2');
      expect(updated.progressFraction, 1 / 3);
    });
  });
}

Routine _routine() {
  final now = DateTime(2026);
  return Routine(
    metadata: EntityMetadata(id: 'routine-1', createdAt: now, updatedAt: now, ownerId: 'profile-1'),
    profileId: 'profile-1',
    title: 'Manana tranquila',
  );
}

RoutineStep _step(String id, int order) {
  final now = DateTime(2026);
  return RoutineStep(
    metadata: EntityMetadata(id: id, createdAt: now, updatedAt: now, ownerId: 'profile-1'),
    routineId: 'routine-1',
    title: 'Paso $order',
    order: order,
    estimatedMinutes: 2,
  );
}
