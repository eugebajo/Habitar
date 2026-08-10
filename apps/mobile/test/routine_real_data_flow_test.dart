import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

void main() {
  test('profile summary uses persisted routine steps when no session exists',
      () async {
    final profileRepository = InMemoryProfileRepository();
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final child = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final teen = await profileRepository.createTeenProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 14,
    );
    await routineRepository.createRoutine(
      profileId: child.metadata.id,
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
    );
    final service = ProfileService(
      repository: profileRepository,
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      habitRepository: InMemoryHabitRepository(),
      progressRepository: InMemoryHabitProgressRepository(),
    );

    final summaries = await service.summariesForFamily('family-1');
    final childSummary =
        summaries.singleWhere((summary) => summary.profileId == child.metadata.id);
    final teenSummary =
        summaries.singleWhere((summary) => summary.profileId == teen.metadata.id);

    expect(childSummary.activeRoutineTitle, 'Prepararse para la escuela');
    expect(childSummary.nextTaskTitle, 'Aseo');
    expect(childSummary.pendingTasks, 3);
    expect(teenSummary.activeRoutineTitle, isNull);
    expect(teenSummary.nextTaskTitle, isNull);
    expect(teenSummary.pendingTasks, 0);
  });

  test('starting an existing routine opens the first persisted routine step',
      () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final routine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      supportRepository: InMemorySupportRequestRepository(),
    );

    final session = await service.startExistingRoutine(routine, steps: steps);
    final restored =
        await sessionRepository.activeSessionForProfile('nico-child');

    expect(session.activeStep?.title, 'Aseo');
    expect(restored?.id, session.id);
    expect(restored?.activeStep?.title, 'Aseo');
    expect(restored?.orderedSteps.map((step) => step.title), [
      'Aseo',
      'Vestirse',
      'Mochila',
    ]);
  });

  test('completing one of four steps persists session progress', () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final profileRepository = InMemoryProfileRepository();
    final child = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final routine = await routineRepository.createRoutine(
      profileId: child.metadata.id,
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
        'Salir',
      ],
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      supportRepository: InMemorySupportRequestRepository(),
    );

    final session = await service.startExistingRoutine(routine, steps: steps);
    final updated = await service.completeStep(session);
    final restored = await sessionRepository.byId(session.id);
    final profileService = ProfileService(
      repository: profileRepository,
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      habitRepository: InMemoryHabitRepository(),
      progressRepository: InMemoryHabitProgressRepository(),
    );
    final summary =
        (await profileService.summariesForFamily('family-1')).single;

    expect(restored?.completedStepIds.length, 1);
    expect(restored?.activeStep?.title, 'Vestirse');
    expect(updated.progressFraction, .25);
    expect(summary.completedGoals, 1);
    expect(summary.pendingTasks, 3);
  });

  test('completing four of four steps completes session and clears next task',
      () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final profileRepository = InMemoryProfileRepository();
    final child = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final routine = await routineRepository.createRoutine(
      profileId: child.metadata.id,
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
        'Salir',
      ],
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      supportRepository: InMemorySupportRequestRepository(),
    );

    var session = await service.startExistingRoutine(routine, steps: steps);
    for (var index = 0; index < 4; index += 1) {
      session = await service.completeStep(session);
    }
    final restored = await sessionRepository.activeSessionForProfile(
      child.metadata.id,
    );
    final profileService = ProfileService(
      repository: profileRepository,
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      habitRepository: InMemoryHabitRepository(),
      progressRepository: InMemoryHabitProgressRepository(),
    );
    final summary =
        (await profileService.summariesForFamily('family-1')).single;

    expect(restored?.status, RoutineSessionStatus.completed);
    expect(
      restored?.completedStepIds,
      steps.map((step) => step.metadata.id).toList(growable: false),
    );
    expect(restored?.activeStep, isNull);
    expect(summary.completedGoals, 4);
    expect(summary.pendingTasks, 0);
    expect(summary.progressFraction, 1);
    expect(summary.nextTaskTitle, isNull);
  });

  test('help pause and extra time persist support requests for the profile',
      () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final supportRepository = InMemorySupportRequestRepository();
    final routine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      supportRepository: supportRepository,
    );

    final session = await service.startExistingRoutine(routine, steps: steps);
    await service.requestHelp(session);
    await service.pause(session, RoutinePauseReason.sensory);
    await service.requestMoreTime(session);

    final requests = await supportRepository.requestsForProfile('nico-child');

    expect(requests.map((request) => request.kind), [
      'help',
      'pause',
      'extra_time',
    ]);
    expect(requests.every((request) => request.note!.contains(session.id)),
        isTrue);
  });

  test('requests and progress stay isolated between child and teen profiles',
      () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final supportRepository = InMemorySupportRequestRepository();
    final childRoutine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Prepararse para la escuela',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
    );
    await routineRepository.createRoutine(
      profileId: 'nico-teen',
      title: 'Organizar la tarde',
      stepTitles: [
        'Revisar tareas',
        'Preparar mochila',
        'Descansar',
      ],
    );
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      supportRepository: supportRepository,
    );
    final childSteps =
        await routineRepository.stepsForRoutine(childRoutine.metadata.id);

    final childSession =
        await service.startExistingRoutine(childRoutine, steps: childSteps);
    await service.completeStep(childSession);
    await service.requestHelp(childSession);

    final childRequests =
        await supportRepository.requestsForProfile('nico-child');
    final teenRequests = await supportRepository.requestsForProfile('nico-teen');
    final teenSession =
        await sessionRepository.activeSessionForProfile('nico-teen');

    expect(childRequests, hasLength(1));
    expect(teenRequests, isEmpty);
    expect(teenSession, isNull);
  });
}
