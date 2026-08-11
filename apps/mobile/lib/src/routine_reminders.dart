import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_notifications/notifications.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

import 'dependencies.dart';

const _routineReminderHorizon = Duration(days: 7);

Future<void> cancelRoutineReminders(WidgetRef ref, String routineId) async {
  final scheduler = ref.read(reminderSchedulerProvider);
  await scheduler.cancel('$routineId-start');
  await scheduler.cancel('$routineId-follow-up');
  for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
    await scheduler.cancel('$routineId-start-$weekday');
    await scheduler.cancel('$routineId-follow-up-$weekday');
  }
}

Future<void> scheduleRoutineReminders(
  WidgetRef ref, {
  required Routine routine,
  required List<RoutineStep> steps,
  required String profileName,
  DateTime? now,
}) async {
  await cancelRoutineReminders(ref, routine.metadata.id);
  if (!routine.hasSchedule ||
      routine.metadata.status != EntityStatus.active ||
      steps.isEmpty ||
      routine.silentNotification) {
    return;
  }

  final currentInstant = now ?? DateTime.now();
  final today = habitarFunctionalDate(currentInstant);
  final latestSession = await ref
      .read(routineSessionRepositoryProvider)
      .latestSessionForRoutineDate(
        routineId: routine.metadata.id,
        localDate: today,
      );
  final completedToday =
      latestSession?.status == RoutineSessionStatus.completed &&
          sameHabitarFunctionalDate(latestSession!.sessionDate, today);

  final scheduler = ref.read(reminderSchedulerProvider);
  final dates = _nextScheduledDates(routine, now: currentInstant);
  for (final scheduledAt in dates) {
    if (completedToday && sameHabitarFunctionalDate(scheduledAt, today)) {
      continue;
    }
    final weekday = scheduledAt.weekday;
    await scheduler.schedule(
      LocalReminderRequest(
        id: '${routine.metadata.id}-start-$weekday',
        title: 'Es hora de ${routine.title}',
        body: '$profileName puede empezar con: ${steps.first.title}',
        scheduledAt: scheduledAt,
        intensity: ReminderIntensity.visible,
        channelId: 'routine_reminders',
        vibration: routine.vibrationEnabled,
        sound: routine.soundEnabled,
      ),
    );
    await scheduler.schedule(
      LocalReminderRequest(
        id: '${routine.metadata.id}-follow-up-$weekday',
        title: 'Rutina pendiente',
        body: 'La rutina todavia esta pendiente.',
        scheduledAt: scheduledAt.add(
          Duration(minutes: routine.reminderIntervalMinutes),
        ),
        intensity: ReminderIntensity.visible,
        channelId: 'routine_reminders',
        vibration: routine.vibrationEnabled,
        sound: routine.soundEnabled,
      ),
    );
  }
}

List<DateTime> _nextScheduledDates(Routine routine, {DateTime? now}) {
  final hour = routine.scheduledHour;
  final minute = routine.scheduledMinute;
  if (hour == null || minute == null) {
    return const [];
  }

  final currentInstant = now ?? DateTime.now();
  if (routine.repeatPolicy == RoutineRepeatPolicy.once) {
    final onceDate = habitarFunctionalDate(routine.metadata.createdAt);
    final scheduledAt = DateTime(
      onceDate.year,
      onceDate.month,
      onceDate.day,
      hour,
      minute,
    );
    return scheduledAt.isAfter(currentInstant) ? [scheduledAt] : const [];
  }

  final end = currentInstant.add(_routineReminderHorizon);
  final weekdays = _weekdaysFor(routine);
  final dates = <DateTime>[];
  final currentDate = habitarFunctionalDate(currentInstant);
  for (var day = DateTime(currentDate.year, currentDate.month, currentDate.day);
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))) {
    if (!weekdays.contains(day.weekday)) {
      continue;
    }
    final scheduledAt = DateTime(day.year, day.month, day.day, hour, minute);
    if (scheduledAt.isAfter(currentInstant)) {
      dates.add(scheduledAt);
    }
  }
  return dates;
}

Set<int> _weekdaysFor(Routine routine) {
  if (routine.repeatPolicy == RoutineRepeatPolicy.daily) {
    return {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    };
  }
  if (routine.repeatPolicy == RoutineRepeatPolicy.weekdays) {
    return {
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    };
  }
  if (routine.weekdays.isNotEmpty) {
    return routine.weekdays.toSet();
  }
  return {habitarFunctionalDate().weekday};
}
