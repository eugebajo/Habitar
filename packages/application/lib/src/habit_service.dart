import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';

import 'repositories.dart';

class CreateHabitInput {
  const CreateHabitInput({
    required this.profileId,
    required this.profileKind,
    required this.title,
    required this.minimumVersion,
    this.confirmedOverride = false,
  });

  final String profileId;
  final ProfileKind profileKind;
  final String title;
  final String minimumVersion;
  final bool confirmedOverride;
}

class CreateHabitResult {
  const CreateHabitResult(
      {required this.habit, required this.plan, required this.wasActivated});

  final Habit habit;
  final HabitActivationPlan plan;
  final bool wasActivated;
}

class HabitService {
  const HabitService({
    required this.habitRepository,
    required this.progressRepository,
    this.engine = const HabitEngine(),
  });

  final HabitRepository habitRepository;
  final HabitProgressRepository progressRepository;
  final HabitEngine engine;

  Future<CreateHabitResult> createNewHabit(CreateHabitInput input) async {
    final existing = await habitRepository.habitsForProfile(input.profileId);
    final draft = await habitRepository.proposeHabit(
      profileId: input.profileId,
      title: input.title,
      minimumVersion: input.minimumVersion,
      status: HabitStatus.newHabit,
    );
    final plan = engine.evaluateActivation(
        habit: draft, profileKind: input.profileKind, activeHabits: existing);
    if (!plan.decision.isAllowed && !input.confirmedOverride) {
      final paused = Habit(
        metadata: draft.metadata,
        profileId: draft.profileId,
        title: draft.title,
        status: HabitStatus.proposed,
        minimumVersion: draft.minimumVersion,
      );
      await habitRepository.saveHabit(paused);
      return CreateHabitResult(habit: paused, plan: plan, wasActivated: false);
    }
    return CreateHabitResult(habit: draft, plan: plan, wasActivated: true);
  }

  Future<List<Habit>> habitsForProfile(String profileId) {
    return habitRepository.habitsForProfile(profileId);
  }

  Future<void> recordMinimumVersion(
      {required String habitId,
      required bool completed,
      required int helpLevel,
      required int ease}) {
    return progressRepository.record(
      HabitProgressEntry(
        habitId: habitId,
        recordedAt: DateTime.now(),
        completedMinimumVersion: completed,
        helpLevel: helpLevel,
        ease: ease,
      ),
    );
  }

  Future<List<WeeklyHabitSummary>> weeklySummaries(String profileId) async {
    final habits = await habitRepository.habitsForProfile(profileId);
    final summaries = <WeeklyHabitSummary>[];
    for (final habit in habits) {
      final entries =
          await progressRepository.entriesForHabit(habit.metadata.id);
      summaries.add(
          engine.summarizeWeek(habitId: habit.metadata.id, entries: entries));
    }
    return summaries;
  }
}
