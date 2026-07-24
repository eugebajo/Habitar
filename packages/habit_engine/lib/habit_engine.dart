import 'package:habitar_domain/domain.dart';

export 'package:habitar_domain/domain.dart' show HabitActivationDecision, HabitActivationPolicy;

class HabitActivationPlan {
  const HabitActivationPlan({
    required this.habit,
    required this.decision,
    required this.activeNewHabitCount,
    required this.recommendedLimit,
  });

  final Habit habit;
  final HabitActivationDecision decision;
  final int activeNewHabitCount;
  final int recommendedLimit;
}

class HabitProgressEntry {
  const HabitProgressEntry({
    required this.habitId,
    required this.recordedAt,
    required this.completedMinimumVersion,
    required this.helpLevel,
    required this.ease,
    this.note,
  });

  final String habitId;
  final DateTime recordedAt;
  final bool completedMinimumVersion;
  final int helpLevel;
  final int ease;
  final String? note;
}

class WeeklyHabitSummary {
  const WeeklyHabitSummary({
    required this.habitId,
    required this.totalEntries,
    required this.minimumVersionCompletions,
    required this.averageHelpLevel,
    required this.averageEase,
  });

  final String habitId;
  final int totalEntries;
  final int minimumVersionCompletions;
  final double averageHelpLevel;
  final double averageEase;

  String get supportiveInsight {
    if (totalEntries == 0) {
      return 'Quizás conviene mantener este hábito simple una semana más.';
    }
    if (averageHelpLevel <= 1.5) {
      return 'Este hábito se realizó con menos ayuda.';
    }
    if (averageEase < 2.5) {
      return 'Este hábito puede necesitar una versión mínima más pequeña.';
    }
    return 'Hay avances registrados sin usar rachas ni castigos.';
  }
}

class HabitEngine {
  const HabitEngine({this.policy = const HabitActivationPolicy()});

  final HabitActivationPolicy policy;

  HabitActivationPlan evaluateActivation({
    required Habit habit,
    required ProfileKind profileKind,
    required Iterable<Habit> activeHabits,
  }) {
    final activeNewHabitCount = activeHabits.where(_isNewActive).length;
    final decision = policy.evaluate(profileKind: profileKind, activeHabits: [...activeHabits, habit]);
    return HabitActivationPlan(
      habit: habit,
      decision: decision,
      activeNewHabitCount: activeNewHabitCount + 1,
      recommendedLimit: policy.recommendedLimit(profileKind),
    );
  }

  WeeklyHabitSummary summarizeWeek({required String habitId, required Iterable<HabitProgressEntry> entries}) {
    final matching = entries.where((entry) => entry.habitId == habitId).toList(growable: false);
    if (matching.isEmpty) {
      return WeeklyHabitSummary(
        habitId: habitId,
        totalEntries: 0,
        minimumVersionCompletions: 0,
        averageHelpLevel: 0,
        averageEase: 0,
      );
    }

    final completions = matching.where((entry) => entry.completedMinimumVersion).length;
    final helpTotal = matching.fold<int>(0, (total, entry) => total + entry.helpLevel);
    final easeTotal = matching.fold<int>(0, (total, entry) => total + entry.ease);

    return WeeklyHabitSummary(
      habitId: habitId,
      totalEntries: matching.length,
      minimumVersionCompletions: completions,
      averageHelpLevel: helpTotal / matching.length,
      averageEase: easeTotal / matching.length,
    );
  }

  bool _isNewActive(Habit habit) {
    return habit.status == HabitStatus.newHabit || habit.status == HabitStatus.practicing;
  }
}
