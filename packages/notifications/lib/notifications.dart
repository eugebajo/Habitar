enum ReminderIntensity {
  quiet,
  visible,
  persistentAllowed,
  silent,
  wearableOnly
}

enum NotificationPermissionStatus { unknown, denied, granted }

enum ReminderAction {
  startRoutine,
  addFiveMinutes,
  requestHelp,
  skipWithReason
}

enum RoutineSignalKind {
  softVibration,
  doubleVibration,
  shortSound,
  vibrationAndSound,
  silentNotice,
  remindInFive
}

enum NotificationPlatformFeature {
  androidPersistentRoutine,
  iosLiveActivity,
  exactAlarm,
  timeSensitive
}

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
    this.vibration = true,
    this.sound = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;
  final ReminderIntensity intensity;
  final List<ReminderAction> actions;
  final String channelId;
  final bool requiresExactAlarm;
  final bool vibration;
  final bool sound;
}

class RoutineSignalLimits {
  const RoutineSignalLimits({
    this.maxSignalsPerRoutine = 2,
    this.minInterval = const Duration(minutes: 5),
  });

  final int maxSignalsPerRoutine;
  final Duration minInterval;
}

class RoutineSignalHistoryEntry {
  const RoutineSignalHistoryEntry({
    required this.routineId,
    required this.sentAt,
    required this.sentByAdultId,
  });

  final String routineId;
  final DateTime sentAt;
  final String sentByAdultId;
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
    return permissionStatus == NotificationPermissionStatus.granted &&
        intensity != ReminderIntensity.silent;
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

  ReminderPlan planManualSignal({
    required String routineId,
    required String routineTitle,
    required String firstStepTitle,
    required String sentByName,
    required DateTime now,
    required RoutineSignalKind kind,
    required NotificationConsent consent,
    required List<RoutineSignalHistoryEntry> recentSignals,
    RoutineSignalLimits limits = const RoutineSignalLimits(),
  }) {
    if (!consent.canSchedule && kind != RoutineSignalKind.silentNotice) {
      return const ReminderPlan(
        requests: [],
        blockedReason:
            'Las notificaciones no tienen permiso para enviar señales.',
      );
    }

    final routineSignals = recentSignals
        .where((entry) => entry.routineId == routineId)
        .toList(growable: false);
    if (routineSignals.length >= limits.maxSignalsPerRoutine) {
      return const ReminderPlan(
        requests: [],
        blockedReason:
            'Ya se enviaron las señales permitidas para esta rutina.',
      );
    }
    if (routineSignals.isNotEmpty) {
      final latest = routineSignals
          .map((entry) => entry.sentAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (now.difference(latest) < limits.minInterval) {
        return const ReminderPlan(
          requests: [],
          blockedReason: 'Esperá unos minutos antes de enviar otra señal.',
        );
      }
    }

    final scheduledAt = kind == RoutineSignalKind.remindInFive
        ? now.add(const Duration(minutes: 5))
        : now;
    final sound = kind == RoutineSignalKind.shortSound ||
        kind == RoutineSignalKind.vibrationAndSound;
    final vibration = kind == RoutineSignalKind.softVibration ||
        kind == RoutineSignalKind.doubleVibration ||
        kind == RoutineSignalKind.vibrationAndSound;
    final intensity = kind == RoutineSignalKind.silentNotice
        ? ReminderIntensity.silent
        : consent.intensity;

    return ReminderPlan(
      requests: [
        LocalReminderRequest(
          id: '$routineId-signal-${now.millisecondsSinceEpoch}',
          title: routineTitle,
          body: '$sentByName envió una señal. Primer paso: $firstStepTitle',
          scheduledAt: scheduledAt,
          intensity: intensity,
          actions: const [
            ReminderAction.startRoutine,
            ReminderAction.requestHelp,
            ReminderAction.addFiveMinutes,
          ],
          channelId: 'routine_signals',
          vibration: vibration,
          sound: sound,
        ),
      ],
      blockedReason: null,
    );
  }

  ReminderPlan planRoutineStart({
    required String routineId,
    required String routineTitle,
    required String firstStepTitle,
    required DateTime scheduledAt,
    required NotificationConsent consent,
  }) {
    if (!consent.canSchedule) {
      return const ReminderPlan(
          requests: [],
          blockedReason:
              'Las notificaciones no tienen permiso o están en modo silencioso.');
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
        requiresExactAlarm:
            consent.intensity == ReminderIntensity.persistentAllowed,
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
