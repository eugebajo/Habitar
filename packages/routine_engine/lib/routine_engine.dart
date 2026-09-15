import 'package:habitar_domain/domain.dart';

enum RoutineSessionStatus { running, paused, completed, postponed }

enum RoutinePauseReason { sensory, interruption }

const habitarFunctionalTimeZoneName = 'America/Asuncion';
// Paraguay uses permanent UTC-3 since October 2024 under Ley N. 7354.
// Keep this aligned with PostgreSQL `at time zone 'America/Asuncion'`.
// If Paraguay returns to seasonal time, replace this fixed offset with a
// timezone database based implementation.
const _asuncionUtcOffset = Duration(hours: -3);

// Every call site in this repo that needs "today" first calls
// habitarFunctionalDate() to get the calendar day, then hands that value
// to a repository method or to sameHabitarFunctionalDate for comparison -
// which calls habitarFunctionalDate() again internally. That means this
// function routinely receives its own output as input, not just raw
// instants like DateTime.now() or a session's startedAt. It has to give
// the same answer either way - see the two properties below.
//
// 1. TZ-independent output. The old version returned a *local* DateTime
//    (DateTime(y, m, d), no .utc) - a value whose actual instant depends
//    on whatever timezone the running process happens to be in. The same
//    session, compared on a machine set to America/Asuncion vs. one set to
//    UTC, produced DateTime objects for a nominally "identical" calendar
//    day that did not represent the same instant. Returning DateTime.utc
//    here instead makes the result a portable calendar-date value: its
//    meaning no longer depends on the process's local timezone setting.
// 2. Idempotent. Applying the Asuncion offset a second time to a value
//    that is already a functional date silently rolls it back a day
//    (e.g. midnight Jan 5 minus 3 hours lands on Jan 4). Combined with (1)
//    being wrong, this is what made
//    "schedule a routine, complete it, ask again the same day" resolve to
//    two different days depending on the runner's timezone - it always
//    passed on a machine set to America/Asuncion (where the double
//    conversion happened to cancel out) and could fail anywhere else,
//    including plain UTC. See habitar_functional_date_test.dart for the
//    regression test and the routine_service/routine_reminders call sites
//    for why the double call is unavoidable without a bigger refactor.
DateTime habitarFunctionalDate([DateTime? instant]) {
  final value = instant ?? DateTime.now();
  if (_isAlreadyFunctionalDate(value)) {
    return DateTime.utc(value.year, value.month, value.day);
  }
  final utc = value.toUtc();
  final asuncion = utc.add(_asuncionUtcOffset);
  return DateTime.utc(asuncion.year, asuncion.month, asuncion.day);
}

// A value produced by habitarFunctionalDate is always UTC-flagged exact
// midnight. A genuine instant - DateTime.now(), a session's startedAt, a
// parsed Supabase timestamp - essentially never lands there by chance, so
// this reliably tells "already converted" apart from "still needs
// converting" without introducing a separate wrapper type for dates that
// would have to be threaded through the entities, repositories and JSON
// (de)serialization everywhere sessionDate/localDate are used.
bool _isAlreadyFunctionalDate(DateTime value) =>
    value.isUtc &&
    value.hour == 0 &&
    value.minute == 0 &&
    value.second == 0 &&
    value.millisecond == 0 &&
    value.microsecond == 0;

bool sameHabitarFunctionalDate(DateTime first, DateTime second) {
  final a = habitarFunctionalDate(first);
  final b = habitarFunctionalDate(second);
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class RoutineProgress {
  const RoutineProgress(
      {required this.routine,
      required this.steps,
      required this.activeStepIndex});

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
    DateTime? sessionDate,
    this.status = RoutineSessionStatus.running,
    this.completedStepIds = const [],
    this.skippedStepIds = const [],
    this.extraMinutesByStepId = const {},
    this.pauseReason,
    this.helpRequested = false,
    this.postponedUntil,
    this.completedAt,
  }) : sessionDate = sessionDate ?? startedAt;

  final String id;
  final Routine routine;
  final List<RoutineStep> steps;
  final int activeStepIndex;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime sessionDate;
  final RoutineSessionStatus status;
  final List<String> completedStepIds;
  final List<String> skippedStepIds;
  final Map<String, int> extraMinutesByStepId;
  final RoutinePauseReason? pauseReason;
  final bool helpRequested;
  final DateTime? postponedUntil;
  final DateTime? completedAt;

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
      return !completedStepIds.contains(step.metadata.id) &&
          !skippedStepIds.contains(step.metadata.id);
    });
    return remaining.fold<int>(0, (total, step) {
      return total +
          (step.estimatedMinutes ?? 0) +
          (extraMinutesByStepId[step.metadata.id] ?? 0);
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
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? sessionDate,
  }) {
    return RoutineSession(
      id: id,
      routine: routine,
      steps: steps,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionDate: sessionDate ?? this.sessionDate,
      status: status ?? this.status,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      skippedStepIds: skippedStepIds ?? this.skippedStepIds,
      extraMinutesByStepId: extraMinutesByStepId ?? this.extraMinutesByStepId,
      pauseReason: clearPauseReason ? null : pauseReason ?? this.pauseReason,
      helpRequested: helpRequested ?? this.helpRequested,
      postponedUntil:
          clearPostponedUntil ? null : postponedUntil ?? this.postponedUntil,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
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
      throw ArgumentError.value(steps.length, 'steps',
          'A routine needs at least 3 steps in the MVP.');
    }
    final ordered = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return RoutineSession(
      id: sessionId,
      routine: routine,
      steps: ordered,
      activeStepIndex: 0,
      startedAt: now,
      updatedAt: now,
      sessionDate: habitarFunctionalDate(now),
    );
  }

  RoutineSession completeActiveStep(RoutineSession session, DateTime now) {
    final activeStep = session.activeStep;
    if (activeStep == null) {
      return session.copyWith(
        status: RoutineSessionStatus.completed,
        updatedAt: now,
        completedAt: now,
      );
    }

    final completed = {...session.completedStepIds, activeStep.metadata.id}
        .toList(growable: false);
    final nextIndex = _nextOpenIndex(session, completed, session.skippedStepIds,
        fromIndex: session.activeStepIndex + 1);
    return session.copyWith(
      activeStepIndex: nextIndex,
      completedStepIds: completed,
      status: nextIndex >= session.steps.length
          ? RoutineSessionStatus.completed
          : RoutineSessionStatus.running,
      updatedAt: now,
      completedAt:
          nextIndex >= session.steps.length ? now : session.completedAt,
      clearPauseReason: true,
      clearPostponedUntil: true,
    );
  }

  RoutineSession requestMoreTime(RoutineSession session,
      {required int minutes, required DateTime now}) {
    final activeStep = session.activeStep;
    if (activeStep == null || minutes <= 0) {
      return session;
    }
    final currentExtra =
        session.extraMinutesByStepId[activeStep.metadata.id] ?? 0;
    final updatedExtras = Map<String, int>.of(session.extraMinutesByStepId);
    updatedExtras[activeStep.metadata.id] = currentExtra + minutes;
    return session.copyWith(
        extraMinutesByStepId: updatedExtras, updatedAt: now);
  }

  RoutineSession pause(RoutineSession session,
      {required RoutinePauseReason reason, required DateTime now}) {
    return session.copyWith(
        status: RoutineSessionStatus.paused,
        pauseReason: reason,
        updatedAt: now);
  }

  RoutineSession resume(RoutineSession session, DateTime now) {
    return session.copyWith(
        status: RoutineSessionStatus.running,
        updatedAt: now,
        clearPauseReason: true,
        clearPostponedUntil: true);
  }

  RoutineSession postpone(RoutineSession session,
      {required Duration duration, required DateTime now}) {
    return session.copyWith(
      status: RoutineSessionStatus.postponed,
      postponedUntil: now.add(duration),
      updatedAt: now,
    );
  }

  RoutineSession requestHelp(RoutineSession session, DateTime now) {
    return session.copyWith(helpRequested: true, updatedAt: now);
  }

  RoutineSession skipActiveStep(RoutineSession session,
      {required DateTime now}) {
    final activeStep = session.activeStep;
    if (activeStep == null) {
      return session.copyWith(
        status: RoutineSessionStatus.completed,
        updatedAt: now,
        completedAt: now,
      );
    }
    final skipped = {...session.skippedStepIds, activeStep.metadata.id}
        .toList(growable: false);
    final nextIndex = _nextOpenIndex(session, session.completedStepIds, skipped,
        fromIndex: session.activeStepIndex + 1);
    return session.copyWith(
      activeStepIndex: nextIndex,
      skippedStepIds: skipped,
      status: nextIndex >= session.steps.length
          ? RoutineSessionStatus.completed
          : RoutineSessionStatus.running,
      updatedAt: now,
      completedAt:
          nextIndex >= session.steps.length ? now : session.completedAt,
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
      if (!completedStepIds.contains(stepId) &&
          !skippedStepIds.contains(stepId)) {
        return index;
      }
    }
    return ordered.length;
  }
}
