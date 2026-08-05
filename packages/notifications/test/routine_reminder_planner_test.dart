import 'package:habitar_notifications/notifications.dart';
import 'package:test/test.dart';

void main() {
  group('RoutineReminderPlanner', () {
    test('blocks reminders without consent', () {
      final plan = const RoutineReminderPlanner().planRoutineStart(
        routineId: 'routine-1',
        routineTitle: 'Prepararse',
        firstStepTitle: 'Zapatos',
        scheduledAt: DateTime(2026),
        consent: const NotificationConsent(
          profileId: 'profile-1',
          permissionStatus: NotificationPermissionStatus.denied,
          intensity: ReminderIntensity.visible,
        ),
      );

      expect(plan.isBlocked, isTrue);
      expect(plan.requests, isEmpty);
    });

    test('limits repeated manual signals for the same routine', () {
      final now = DateTime(2026, 1, 1, 8);
      final planner = const RoutineReminderPlanner();
      final consent = const NotificationConsent(
        profileId: 'profile-1',
        permissionStatus: NotificationPermissionStatus.granted,
        intensity: ReminderIntensity.visible,
      );

      final first = planner.planManualSignal(
        routineId: 'routine-1',
        routineTitle: 'Prepararse',
        firstStepTitle: 'Zapatos',
        sentByName: 'Mamá',
        now: now,
        kind: RoutineSignalKind.softVibration,
        consent: consent,
        recentSignals: const [],
      );
      final blocked = planner.planManualSignal(
        routineId: 'routine-1',
        routineTitle: 'Prepararse',
        firstStepTitle: 'Zapatos',
        sentByName: 'Mamá',
        now: now.add(const Duration(minutes: 2)),
        kind: RoutineSignalKind.softVibration,
        consent: consent,
        recentSignals: [
          RoutineSignalHistoryEntry(
            routineId: 'routine-1',
            sentAt: now,
            sentByAdultId: 'adult-1',
          ),
        ],
      );

      expect(first.requests.single.channelId, 'routine_signals');
      expect(
          first.requests.single.actions, contains(ReminderAction.startRoutine));
      expect(blocked.isBlocked, isTrue);
    });

    test('adds allowed routine actions to a visible reminder', () {
      final plan = const RoutineReminderPlanner().planRoutineStart(
        routineId: 'routine-1',
        routineTitle: 'Prepararse',
        firstStepTitle: 'Zapatos',
        scheduledAt: DateTime(2026),
        consent: const NotificationConsent(
          profileId: 'profile-1',
          permissionStatus: NotificationPermissionStatus.granted,
          intensity: ReminderIntensity.visible,
        ),
      );

      expect(
          plan.requests.single.actions, contains(ReminderAction.startRoutine));
      expect(plan.requests.single.actions,
          contains(ReminderAction.addFiveMinutes));
      expect(plan.requests.single.requiresExactAlarm, isFalse);
    });
  });
}
