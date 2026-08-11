import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

bool routineAppliesOnDate(
  Routine routine,
  DateTime localDate, {
  List<RoutineOverride> overrides = const [],
}) {
  if (routine.metadata.status != EntityStatus.active) {
    return false;
  }

  final pausedOrSkipped = overrides.any((override) {
    if (override.routineId != routine.metadata.id) {
      return false;
    }
    if (!_sameLocalDay(override.date, localDate)) {
      return false;
    }
    return override.isPaused ||
        override.type == RoutineOverrideType.pauseToday ||
        override.type == RoutineOverrideType.skipToday;
  });
  if (pausedOrSkipped) {
    return false;
  }

  return switch (routine.repeatPolicy) {
    RoutineRepeatPolicy.daily => true,
    RoutineRepeatPolicy.weekdays => localDate.weekday >= DateTime.monday &&
        localDate.weekday <= DateTime.friday,
    RoutineRepeatPolicy.once =>
      _sameLocalDay(routine.metadata.createdAt, localDate),
    RoutineRepeatPolicy.weekly ||
    RoutineRepeatPolicy.custom =>
      routine.weekdays.isEmpty
          ? localDate.weekday == routine.metadata.createdAt.weekday
          : routine.weekdays.contains(localDate.weekday),
  };
}

bool routineIsPendingOnDate(
  Routine routine,
  DateTime localDate, {
  List<RoutineOverride> overrides = const [],
  RoutineSession? sessionToday,
}) {
  if (!routineAppliesOnDate(routine, localDate, overrides: overrides)) {
    return false;
  }
  return sessionToday?.status != RoutineSessionStatus.completed;
}

Future<List<Routine>> routinesForToday({
  required List<Routine> routines,
  required DateTime localDate,
  required Future<List<RoutineOverride>> Function() loadOverrides,
  required Future<RoutineSession?> Function(Routine routine) loadSessionToday,
}) async {
  final overrides = await loadOverrides();
  final available = <Routine>[];
  for (final routine in routines) {
    final sessionToday = await loadSessionToday(routine);
    if (routineIsPendingOnDate(
      routine,
      localDate,
      overrides: overrides,
      sessionToday: sessionToday,
    )) {
      available.add(routine);
    }
  }
  available.sort((a, b) {
    final aMinutes = (a.scheduledHour ?? 23) * 60 + (a.scheduledMinute ?? 59);
    final bMinutes = (b.scheduledHour ?? 23) * 60 + (b.scheduledMinute ?? 59);
    final byTime = aMinutes.compareTo(bMinutes);
    return byTime == 0 ? a.title.compareTo(b.title) : byTime;
  });
  return available;
}

bool _sameLocalDay(DateTime first, DateTime second) {
  return sameHabitarFunctionalDate(first, second);
}
