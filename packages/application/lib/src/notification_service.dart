import 'package:habitar_notifications/notifications.dart';

import 'repositories.dart';

class NotificationService {
  NotificationService({
    required this.preferenceRepository,
    required this.scheduler,
    this.planner = const RoutineReminderPlanner(),
  });

  final NotificationPreferenceRepository preferenceRepository;
  final LocalReminderScheduler scheduler;
  final RoutineReminderPlanner planner;
  final List<RoutineSignalHistoryEntry> _signalHistory = [];

  Future<NotificationConsent> saveConsent({
    required String profileId,
    required NotificationPermissionStatus permissionStatus,
    required ReminderIntensity intensity,
  }) {
    return preferenceRepository.saveConsent(
      NotificationConsent(
        profileId: profileId,
        permissionStatus: permissionStatus,
        intensity: intensity,
      ),
    );
  }

  Future<ReminderPlan> sendRoutineSignal({
    required String profileId,
    required String routineId,
    required String routineTitle,
    required String firstStepTitle,
    required String sentByAdultId,
    required String sentByName,
    required RoutineSignalKind kind,
    DateTime? now,
  }) async {
    final consent = await preferenceRepository.consentForProfile(profileId);
    if (consent == null) {
      return const ReminderPlan(
          requests: [],
          blockedReason: 'Primero configura permisos de recordatorios.');
    }
    final sentAt = now ?? DateTime.now();
    final plan = planner.planManualSignal(
      routineId: routineId,
      routineTitle: routineTitle,
      firstStepTitle: firstStepTitle,
      sentByName: sentByName,
      now: sentAt,
      kind: kind,
      consent: consent,
      recentSignals: _signalHistory,
    );
    for (final request in plan.requests) {
      await scheduler.schedule(request);
    }
    if (!plan.isBlocked) {
      _signalHistory.add(RoutineSignalHistoryEntry(
        routineId: routineId,
        sentAt: sentAt,
        sentByAdultId: sentByAdultId,
      ));
    }
    return plan;
  }

  Future<ReminderPlan> scheduleRoutineStart({
    required String profileId,
    required String routineId,
    required String routineTitle,
    required String firstStepTitle,
    required DateTime scheduledAt,
  }) async {
    final consent = await preferenceRepository.consentForProfile(profileId);
    if (consent == null) {
      return const ReminderPlan(
          requests: [],
          blockedReason: 'Primero configura permisos de recordatorios.');
    }

    final plan = planner.planRoutineStart(
      routineId: routineId,
      routineTitle: routineTitle,
      firstStepTitle: firstStepTitle,
      scheduledAt: scheduledAt,
      consent: consent,
    );
    for (final request in plan.requests) {
      await scheduler.schedule(request);
    }
    return plan;
  }
}
