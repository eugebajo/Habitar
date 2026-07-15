import 'package:habitar_routine_engine/routine_engine.dart';

enum WearablePlatform { watchOS, wearOS }

enum WearableConnectionStatus { unavailable, disconnected, connected, syncing }

enum WearableQuickAction { completeStep, addFiveMinutes, requestHelp, postpone, pause, resume }

enum WearableTransport { backend, watchConnectivity, wearDataLayer, pushNotification }

class WearableCapabilitySet {
  const WearableCapabilitySet({
    required this.platform,
    required this.transports,
    required this.quickActions,
    required this.supportsHaptics,
    required this.supportsTileOrComplication,
  });

  final WearablePlatform platform;
  final List<WearableTransport> transports;
  final List<WearableQuickAction> quickActions;
  final bool supportsHaptics;
  final bool supportsTileOrComplication;
}

class WearableRoutineSnapshot {
  const WearableRoutineSnapshot({
    required this.sessionId,
    required this.routineTitle,
    required this.currentStepTitle,
    required this.nextStepTitle,
    required this.progressFraction,
    required this.remainingMinutes,
    required this.status,
    required this.updatedAt,
  });

  final String sessionId;
  final String routineTitle;
  final String currentStepTitle;
  final String nextStepTitle;
  final double progressFraction;
  final int remainingMinutes;
  final RoutineSessionStatus status;
  final DateTime updatedAt;

  bool get isActionable {
    return status == RoutineSessionStatus.running || status == RoutineSessionStatus.paused || status == RoutineSessionStatus.postponed;
  }
}

class WearableCommand {
  const WearableCommand({
    required this.sessionId,
    required this.action,
    required this.createdAt,
    this.minutes,
    this.reason,
  });

  final String sessionId;
  final WearableQuickAction action;
  final DateTime createdAt;
  final int? minutes;
  final String? reason;
}

abstract interface class WearableSyncGateway {
  Future<WearableConnectionStatus> status(WearablePlatform platform);

  Future<void> publishSnapshot(WearablePlatform platform, WearableRoutineSnapshot snapshot);

  Future<List<WearableCommand>> pendingCommands(WearablePlatform platform, String sessionId);
}

class WearableSnapshotMapper {
  const WearableSnapshotMapper();

  WearableRoutineSnapshot fromRoutineSession(RoutineSession session) {
    return WearableRoutineSnapshot(
      sessionId: session.id,
      routineTitle: session.routine.title,
      currentStepTitle: session.activeStep?.title ?? 'Listo',
      nextStepTitle: session.nextStep?.title ?? 'Despues terminamos',
      progressFraction: session.progressFraction.clamp(0, 1).toDouble(),
      remainingMinutes: session.estimatedRemainingMinutes,
      status: session.status,
      updatedAt: session.updatedAt,
    );
  }
}

class WearablePlatformPlanner {
  const WearablePlatformPlanner();

  WearableCapabilitySet capabilitiesFor(WearablePlatform platform) {
    return switch (platform) {
      WearablePlatform.watchOS => const WearableCapabilitySet(
          platform: WearablePlatform.watchOS,
          transports: [WearableTransport.backend, WearableTransport.pushNotification, WearableTransport.watchConnectivity],
          quickActions: [
            WearableQuickAction.completeStep,
            WearableQuickAction.addFiveMinutes,
            WearableQuickAction.requestHelp,
            WearableQuickAction.pause,
            WearableQuickAction.resume,
          ],
          supportsHaptics: true,
          supportsTileOrComplication: true,
        ),
      WearablePlatform.wearOS => const WearableCapabilitySet(
          platform: WearablePlatform.wearOS,
          transports: [WearableTransport.backend, WearableTransport.pushNotification, WearableTransport.wearDataLayer],
          quickActions: [
            WearableQuickAction.completeStep,
            WearableQuickAction.addFiveMinutes,
            WearableQuickAction.requestHelp,
            WearableQuickAction.postpone,
            WearableQuickAction.pause,
            WearableQuickAction.resume,
          ],
          supportsHaptics: true,
          supportsTileOrComplication: true,
        ),
    };
  }
}
