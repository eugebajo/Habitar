import 'package:habitar_domain/domain.dart';
import 'package:habitar_habit_engine/habit_engine.dart';

import 'repositories.dart';

class CreateProfileInput {
  const CreateProfileInput({
    required this.familyId,
    required this.displayName,
    required this.age,
    required this.kind,
  });

  final String familyId;
  final String displayName;
  final int age;
  final ProfileKind kind;
}

class ProfileService {
  const ProfileService({
    required this.repository,
    required this.routineRepository,
    required this.sessionRepository,
    required this.habitRepository,
    required this.progressRepository,
  });

  final ProfileRepository repository;
  final RoutineRepository routineRepository;
  final RoutineSessionRepository sessionRepository;
  final HabitRepository habitRepository;
  final HabitProgressRepository progressRepository;

  Future<AppEntity> createProfile(CreateProfileInput input) {
    if (input.kind == ProfileKind.child) {
      return repository.createChildProfile(
          familyId: input.familyId,
          displayName: input.displayName,
          age: input.age);
    }
    return repository.createTeenProfile(
        familyId: input.familyId,
        displayName: input.displayName,
        age: input.age);
  }

  Future<List<ProfileProgressSummary>> summariesForFamily(
      String familyId) async {
    final children = await repository.childProfiles(familyId);
    final teens = await repository.teenProfiles(familyId);
    final summaries = <ProfileProgressSummary>[];
    for (final profile in children) {
      summaries.add(await _summaryForProfile(
        profileId: profile.metadata.id,
        displayName: profile.displayName,
        age: profile.age,
        kind: ProfileKind.child,
      ));
    }
    for (final profile in teens) {
      summaries.add(await _summaryForProfile(
        profileId: profile.metadata.id,
        displayName: profile.displayName,
        age: profile.age,
        kind: ProfileKind.teen,
      ));
    }
    summaries.sort((a, b) => a.displayName.compareTo(b.displayName));
    return summaries;
  }

  Future<ProfileProgressSummary> _summaryForProfile({
    required String profileId,
    required String displayName,
    required int age,
    required ProfileKind kind,
  }) async {
    final routines = await routineRepository.routinesForProfile(profileId);
    final activeSession =
        await sessionRepository.activeSessionForProfile(profileId);
    final habits = await habitRepository.habitsForProfile(profileId);
    var habitCompletions = 0;
    var habitsWithoutProgress = 0;
    String? firstHabitTask;

    for (final habit in habits) {
      final entries =
          await progressRepository.entriesForHabit(habit.metadata.id);
      final summary = const HabitEngine()
          .summarizeWeek(habitId: habit.metadata.id, entries: entries);
      habitCompletions += summary.minimumVersionCompletions;
      if (entries.isEmpty &&
          (habit.status == HabitStatus.newHabit ||
              habit.status == HabitStatus.practicing ||
              habit.status == HabitStatus.proposed)) {
        habitsWithoutProgress += 1;
        firstHabitTask ??= habit.minimumVersion ?? habit.title;
      }
    }

    final completedRoutineSteps = activeSession?.completedStepIds.length ?? 0;
    final skippedRoutineSteps = activeSession?.skippedStepIds.length ?? 0;
    final activeRoutinePending = activeSession == null
        ? 0
        : activeSession.steps.length -
            completedRoutineSteps -
            skippedRoutineSteps;
    final pendingTasks = activeRoutinePending + habitsWithoutProgress;
    final totalTrackable = activeSession == null
        ? habits.length
        : activeSession.steps.length + habits.length;
    final completedGoals = completedRoutineSteps + habitCompletions;
    final progressFraction = totalTrackable == 0
        ? 0.0
        : (completedGoals / totalTrackable).clamp(0, 1).toDouble();

    return ProfileProgressSummary(
      profileId: profileId,
      displayName: displayName,
      age: age,
      kind: kind,
      routinesCount: routines.length,
      habitsCount: habits.length,
      completedGoals: completedGoals,
      pendingTasks: pendingTasks,
      progressFraction: progressFraction,
      activeRoutineTitle: activeSession?.routine.title,
      nextTaskTitle: activeSession?.activeStep?.title ?? firstHabitTask,
      message: _messageFor(
        completedGoals: completedGoals,
        pendingTasks: pendingTasks,
        progressFraction: progressFraction,
      ),
    );
  }

  String _messageFor({
    required int completedGoals,
    required int pendingTasks,
    required double progressFraction,
  }) {
    if (completedGoals == 0 && pendingTasks == 0) {
      return 'Todavia no hay tareas cargadas. Podemos crear una rutina o un habito pequeno.';
    }
    if (pendingTasks == 0) {
      return 'Todo lo pendiente esta resuelto por ahora.';
    }
    if (progressFraction >= 0.6) {
      return 'Ya hay bastante camino hecho. Conviene cerrar una tarea simple.';
    }
    return 'Hay tareas listas para avanzar de a un paso.';
  }
}

class ProfileProgressSummary {
  const ProfileProgressSummary({
    required this.profileId,
    required this.displayName,
    required this.age,
    required this.kind,
    required this.routinesCount,
    required this.habitsCount,
    required this.completedGoals,
    required this.pendingTasks,
    required this.progressFraction,
    required this.message,
    this.activeRoutineTitle,
    this.nextTaskTitle,
  });

  final String profileId;
  final String displayName;
  final int age;
  final ProfileKind kind;
  final int routinesCount;
  final int habitsCount;
  final int completedGoals;
  final int pendingTasks;
  final double progressFraction;
  final String? activeRoutineTitle;
  final String? nextTaskTitle;
  final String message;
}
