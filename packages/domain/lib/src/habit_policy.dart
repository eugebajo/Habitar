import 'entities.dart';

class HabitActivationDecision {
  const HabitActivationDecision.allowed() : isAllowed = true, warning = null;

  const HabitActivationDecision.requiresAdultOverride(this.warning) : isAllowed = false;

  final bool isAllowed;
  final String? warning;
}

class HabitActivationPolicy {
  const HabitActivationPolicy();

  int recommendedLimit(ProfileKind profileKind) {
    return switch (profileKind) {
      ProfileKind.child => 2,
      ProfileKind.teen => 3,
    };
  }

  HabitActivationDecision evaluate({
    required ProfileKind profileKind,
    required Iterable<Habit> activeHabits,
  }) {
    final newActiveCount = activeHabits.where((habit) {
      return habit.status == HabitStatus.newHabit || habit.status == HabitStatus.practicing;
    }).length;

    final limit = recommendedLimit(profileKind);
    if (newActiveCount <= limit) {
      return const HabitActivationDecision.allowed();
    }

    return HabitActivationDecision.requiresAdultOverride(
      'Activar mas de $limit habitos nuevos puede aumentar la sobrecarga. Conviene consolidar pocos cambios a la vez.',
    );
  }
}
