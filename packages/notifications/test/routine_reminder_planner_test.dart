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

      expect(plan.requests.single.actions, contains(ReminderAction.startRoutine));
      expect(plan.requests.single.actions, contains(ReminderAction.addFiveMinutes));
      expect(plan.requests.single.requiresExactAlarm, isFalse);
    });
  });
}
