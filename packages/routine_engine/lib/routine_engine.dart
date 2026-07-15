import 'package:habitar_domain/domain.dart';

enum RoutineSessionStatus { running, paused, completed, postponed }

enum RoutinePauseReason { sensory, interruption }

class RoutineProgress {
  const RoutineProgress({required this.routine, required this.steps, required this.activeStepIndex});

  final Routine routine;
  final List<RoutineStep> steps;
  final int activeStepIndex;

  RoutineStep? get activeStep {
    if (activeStepIndex < 0 || activeStepIndex >= steps.length) {
      return null;
    }
    return steps[activeStepIndex];
  }

  RoutineStep? get nextStep {
    final nextIndex = activeStepIndex + 1;
    if (nextIndex < 0 || nextIndex >= steps.length) {
      return null;
    }
    return steps[nextIndex];
  }
}

class RoutineSession {
  const RoutineSession({
    required this.id,
    required this.routine,
    required this.steps,
    required this.activeStepIndex,
    required this.startedAt,
    required this.updatedAt,
    this.status = RoutineSessionStatus.running,
    this.completedStepIds = const [],
    this.skippedStepIds = const [],
    this.extraMinutesByStepId = const {},
    this.pauseReason,
    this.helpRequested = false,
    this.postponedUntil,
  });

  final String id;
  final Routine routine;
  final List<RoutineStep> steps;
  final int activeStepIndex;
  final DateTime startedAt;
  final DateTime updatedAt;
  final RoutineSessionStatus status;
  final List<String> completedStepIds;
  final List<String> skippedStepIds;
  final Map<String, int> extraMinutesByStepId;
  final RoutinePauseReason? pauseReason;
  final bool helpRequested;
  final DateTime? postponedUntil;

  RoutineStep? get activeStep {
    if (activeStepIndex < 0 || activeStepIndex >= orderedSteps.length) {
      return null;
    }
    return orderedSteps[activeStepIndex];
  }

  RoutineStep? get nextStep {
    final nextIndex = activeStepIndex + 1;
    if (nextIndex < 0 || nextIndex >= orderedSteps.length) {
      return null;
    }
    return orderedSteps[nextIndex];
  }

  List<RoutineStep> get orderedSteps {
    final ordered = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return ordered;
  }

  double get progressFraction {
    if (steps.isEmpty) {
      return 0;
    }
    return (completedStepIds.length + skippedStepIds.length) / steps.length;
  }

  int get estimatedRemainingMinutes {
    final remaining = orderedSteps.skip(activeStepIndex).where((step) {
      return !completedStepIds.contains(step.metadata.id) && !skippedStepIds.contains(step.metadata.id);
    });
    return remaining.fold<int>(0, (total, step) {
      return total + (step.estimatedMinutes ?? 0) + (extraMinutesByStepId[step.metadata.id] ?? 0);
    });
  }

  RoutineSession copyWith({
    int? activeStepIndex,
    DateTime? updatedAt,
    RoutineSessionStatus? status,
    List<String>? completedStepIds,
    List<String>? skippedStepIds,
    Map<String, int>? extraMinutesByStepId,
    RoutinePauseReason? pauseReason,
    bool clearPauseReason = false,
    bool? helpRequested,
    DateTime? postponedUntil,
    bool clearPostponedUntil = false,
  }) {
    return RoutineSession(
      id: id,
      routine: routine,
      steps: steps,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      skippedStepIds: skippedStepIds ?? this.skippedStepIds,
      extraMinutesByStepId: extraMinutesByStepId ?? this.extraMinutesByStepId,
      pauseReason: clearPauseReason ? null : pauseReason ?? this.pauseReason,
      helpRequested: helpRequested ?? this.helpRequested,
      postponedUntil: clearPostponedUntil ? null : postponedUntil ?? this.postponedUntil,
    );
  }
}

class RoutineEngine {
  const RoutineEngine();

  RoutineSession start({
    required String sessionId,
    required Routine routine,
    required List<RoutineStep> steps,
    required DateTime now,
  }) {
    if (steps.length < 3) {
      throw ArgumentError.value(steps.length, 'steps', 'A routine needs at least 3 steps in the MVP.');
    }
    final ordered = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return RoutineSession(
      id: sessionId,
      routine: routine,
      steps: ordered,
      activeStepIndex: 0,
      startedAt: now,
      updatedAt: now,
    );
  }

  RoutineSession completeActiveStep(RoutineSession session, DateTime now) {
    final activeStep = session.activeStep;
    if (activeStep == null) {
      return session.copyWith(status: RoutineSessionStatus.completed, updatedAt: now);
    }

    final completed = {...session.completedStepIds, activeStep.metadata.id}.toList(growable: false);
    final nextIndex = _nextOpenIndex(session, completed, session.skippedStepIds, fromIndex: session.activeStepIndex + 1);
    return session.copyWith(
      activeStepIndex: nextIndex,
      completedStepIds: completed,
      status: nextIndex >= session.steps.length ? RoutineSessionStatus.completed : RoutineSessionStatus.running,
      updatedAt: now,
      clearPauseReason: true,
      clearPostponedUntil: true,
    );
  }

  RoutineSession requestMoreTime(RoutineSession session, {required int minutes, required DateTime now}) {
    final activeStep = session.activeStep;
    if (activeStep == null || minutes <= 0) {
      return session;
    }
    final currentExtra = session.extraMinutesByStepId[activeStep.metadata.id] ?? 0;
    final updatedExtras = Map<String, int>.of(session.extraMinutesByStepId);
    updatedExtras[activeStep.metadata.id] = currentExtra + minutes;
    return session.copyWith(extraMinutesByStepId: updatedExtras, updatedAt: now);
  }

  RoutineSession pause(RoutineSession session, {required RoutinePauseReason reason, required DateTime now}) {
    return session.copyWith(status: RoutineSessionStatus.paused, pauseReason: reason, updatedAt: now);
  }

  RoutineSession resume(RoutineSession session, DateTime now) {
    return session.copyWith(status: RoutineSessionStatus.running, updatedAt: now, clearPauseReason: true, clearPostponedUntil: true);
  }

  RoutineSession postpone(RoutineSession session, {required Duration duration, required DateTime now}) {
    return session.copyWith(
      status: RoutineSessionStatus.postponed,
      postponedUntil: now.add(duration),
      updatedAt: now,
    );
  }

  RoutineSession requestHelp(RoutineSession session, DateTime now) {
    return session.copyWith(helpRequested: true, updatedAt: now);
  }

  RoutineSession skipActiveStep(RoutineSession session, {required DateTime now}) {
    final activeStep = session.activeStep;
    if (activeStep == null) {
      return session.copyWith(status: RoutineSessionStatus.completed, updatedAt: now);
    }
    final skipped = {...session.skippedStepIds, activeStep.metadata.id}.toList(growable: false);
    final nextIndex = _nextOpenIndex(session, session.completedStepIds, skipped, fromIndex: session.activeStepIndex + 1);
    return session.copyWith(
      activeStepIndex: nextIndex,
      skippedStepIds: skipped,
      status: nextIndex >= session.steps.length ? RoutineSessionStatus.completed : RoutineSessionStatus.running,
      updatedAt: now,
    );
  }

  int _nextOpenIndex(
    RoutineSession session,
    List<String> completedStepIds,
    List<String> skippedStepIds, {
    required int fromIndex,
  }) {
    final ordered = session.orderedSteps;
    for (var index = fromIndex; index < ordered.length; index += 1) {
      final stepId = ordered[index].metadata.id;
      if (!completedStepIds.contains(stepId) && !skippedStepIds.contains(stepId)) {
        return index;
      }
    }
    return ordered.length;
  }
}
