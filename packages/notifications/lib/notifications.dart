enum ReminderIntensity { quiet, visible, persistentAllowed, silent, wearableOnly }

enum NotificationPermissionStatus { unknown, denied, granted }

enum ReminderAction { startRoutine, addFiveMinutes, requestHelp, skipWithReason }

enum NotificationPlatformFeature { androidPersistentRoutine, iosLiveActivity, exactAlarm, timeSensitive }

class LocalReminderRequest {
  const LocalReminderRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
    required this.intensity,
    this.actions = const [],
    this.channelId = 'routine_reminders',
    this.requiresExactAlarm = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final ReminderIntensity intensity;
  final List<ReminderAction> actions;
  final String channelId;
  final bool requiresExactAlarm;
}

abstract interface class LocalReminderScheduler {
  Future<void> schedule(LocalReminderRequest request);

  Future<void> cancel(String id);
}

abstract interface class NotificationPermissionGateway {
  Future<NotificationPermissionStatus> status();

  Future<NotificationPermissionStatus> request();
}

class NotificationConsent {
  const NotificationConsent({
    required this.profileId,
    required this.permissionStatus,
    required this.intensity,
    this.allowedFeatures = const [],
  });

  final String profileId;
  final NotificationPermissionStatus permissionStatus;
  final ReminderIntensity intensity;
  final List<NotificationPlatformFeature> allowedFeatures;

  bool get canSchedule {
    return permissionStatus == NotificationPermissionStatus.granted && intensity != ReminderIntensity.silent;
  }
}

class ReminderPlan {
  const ReminderPlan({required this.requests, required this.blockedReason});

  final List<LocalReminderRequest> requests;
  final String? blockedReason;

  bool get isBlocked => blockedReason != null;
}

class RoutineReminderPlanner {
  const RoutineReminderPlanner();

  ReminderPlan planRoutineStart({
    required String routineId,
    required String routineTitle,
    required String firstStepTitle,
    required DateTime scheduledAt,
    required NotificationConsent consent,
  }) {
    if (!consent.canSchedule) {
      return const ReminderPlan(requests: [], blockedReason: 'Las notificaciones no tienen permiso o estan en modo silencioso.');
    }

    final actions = [
      ReminderAction.startRoutine,
      ReminderAction.addFiveMinutes,
      ReminderAction.requestHelp,
      ReminderAction.skipWithReason,
    ];

    final requests = <LocalReminderRequest>[
      LocalReminderRequest(
        id: '$routineId-start',
        title: routineTitle,
        body: 'Primer paso: $firstStepTitle',
        scheduledAt: scheduledAt,
        intensity: consent.intensity,
        actions: actions,
        requiresExactAlarm: consent.intensity == ReminderIntensity.persistentAllowed,
      ),
    ];

    if (consent.intensity == ReminderIntensity.persistentAllowed) {
      requests.add(
        LocalReminderRequest(
          id: '$routineId-follow-up',
          title: routineTitle,
          body: 'Podemos empezar, pedir ayuda o sumar 5 minutos.',
          scheduledAt: scheduledAt.add(const Duration(minutes: 5)),
          intensity: consent.intensity,
          actions: actions,
          requiresExactAlarm: true,
        ),
      );
    }

    return ReminderPlan(requests: requests, blockedReason: null);
  }
}

class InMemoryReminderScheduler implements LocalReminderScheduler {
  final List<LocalReminderRequest> scheduled = [];

  @override
  Future<void> cancel(String id) async {
    scheduled.removeWhere((request) => request.id == id);
  }

  @override
  Future<void> schedule(LocalReminderRequest request) async {
    scheduled.removeWhere((existing) => existing.id == request.id);
    scheduled.add(request);
  }
}
