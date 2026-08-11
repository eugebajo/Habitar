import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/routine_reminders.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

void main() {
  testWidgets('completed once routine does not schedule reminders next week',
      (tester) async {
    final scheduler = InMemoryReminderScheduler();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final now = DateTime(2026, 1, 5, 8);
    final routine = _routine(now);
    final steps = [_step('step-1', routine.metadata.id, 'Preparar mochila')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderSchedulerProvider.overrideWithValue(scheduler),
          routineSessionRepositoryProvider.overrideWithValue(sessionRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return TextButton(
                  onPressed: () => scheduleRoutineReminders(
                    ref,
                    routine: routine,
                    steps: steps,
                    profileName: 'Nico',
                    now: now,
                  ),
                  child: const Text('schedule'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('schedule'));
    await tester.pumpAndSettle();

    expect(scheduler.scheduled, hasLength(2));
    expect(
      scheduler.scheduled.map((request) => request.scheduledAt.day).toSet(),
      {5},
    );

    await sessionRepository.save(
      RoutineSession(
        id: 'session-1',
        routine: routine,
        steps: steps,
        activeStepIndex: steps.length,
        startedAt: now,
        updatedAt: now,
        sessionDate: habitarFunctionalDate(now),
        status: RoutineSessionStatus.completed,
        completedStepIds:
            steps.map((step) => step.metadata.id).toList(growable: false),
        completedAt: now,
      ),
    );

    await tester.tap(find.text('schedule'));
    await tester.pumpAndSettle();

    expect(scheduler.scheduled, isEmpty);
  });
}

Routine _routine(DateTime createdAt) {
  return Routine(
    metadata: EntityMetadata(
      id: 'routine-once',
      createdAt: createdAt,
      updatedAt: createdAt,
      ownerId: 'adult-1',
    ),
    profileId: 'profile-1',
    title: 'Preparar un camino',
    stepIds: const ['step-1'],
    scheduledHour: 9,
    scheduledMinute: 0,
    repeatPolicy: RoutineRepeatPolicy.once,
  );
}

RoutineStep _step(String id, String routineId, String title) {
  return RoutineStep(
    metadata: EntityMetadata(
      id: id,
      createdAt: DateTime(2026, 1, 5, 8),
      updatedAt: DateTime(2026, 1, 5, 8),
      ownerId: 'adult-1',
    ),
    routineId: routineId,
    title: title,
    position: 0,
  );
}
