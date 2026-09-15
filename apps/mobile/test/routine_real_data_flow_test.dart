import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/routine_today.dart';
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
    final childSummary = summaries
        .singleWhere((summary) => summary.profileId == child.metadata.id);
    final teenSummary = summaries
        .singleWhere((summary) => summary.profileId == teen.metadata.id);

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
    final active = await sessionRepository.activeSessionForProfile(
      child.metadata.id,
    );
    final restored = await sessionRepository.latestSessionForRoutineDate(
      routineId: routine.metadata.id,
      // habitarFunctionalDate(), not a raw DateTime.now(): every production
      // call site pre-converts before calling into the repository (see the
      // comment on habitarFunctionalDate in routine_engine.dart) - matching
      // that convention here too, rather than relying on the function being
      // able to make sense of a raw instant as well.
      localDate: habitarFunctionalDate(),
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

    expect(active, isNull);
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

  test('completed routine remains visible for progress but is not active',
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
      title: 'Preparar un camino',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
    );

    var session = await service.startExistingRoutine(routine, steps: steps);
    for (var index = 0; index < steps.length; index += 1) {
      session = await service.completeStep(session);
    }

    final active = await sessionRepository.activeSessionForRoutineToday(
      routineId: routine.metadata.id,
      localDate: habitarFunctionalDate(),
    );
    final sessionsToday = await sessionRepository.sessionsForProfileDate(
      profileId: child.metadata.id,
      localDate: habitarFunctionalDate(),
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

    expect(active, isNull);
    expect(sessionsToday, hasLength(1));
    expect(sessionsToday.single.status, RoutineSessionStatus.completed);
    expect(summary.progressFraction, 1);
    expect(summary.completedGoals, 3);
    expect(summary.pendingTasks, 0);
  });

  test('startExistingRoutine reuses open session and rejects completed day',
      () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final routine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Preparar un camino',
      stepTitles: [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
    );

    final first = await service.startExistingRoutine(routine, steps: steps);
    final second = await service.startExistingRoutine(routine, steps: steps);

    expect(second.id, first.id);

    var completed = first;
    for (var index = 0; index < steps.length; index += 1) {
      completed = await service.completeStep(completed);
    }

    await expectLater(
      service.startExistingRoutine(routine, steps: steps),
      throwsA(isA<StateError>()),
    );
  });

  test('two routines on the same day keep independent sessions', () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final firstRoutine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Prepararse para la escuela',
      stepTitles: const ['Aseo', 'Vestirse', 'Mochila'],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final secondRoutine = await routineRepository.createRoutine(
      profileId: 'nico-child',
      title: 'Leer antes de dormir',
      stepTitles: const ['Elegir libro', 'Leer', 'Guardar'],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
    );

    final first = await service.startExistingRoutine(
      firstRoutine,
      steps: await routineRepository.stepsForRoutine(firstRoutine.metadata.id),
    );
    final second = await service.startExistingRoutine(
      secondRoutine,
      steps: await routineRepository.stepsForRoutine(secondRoutine.metadata.id),
    );

    expect(first.id, isNot(second.id));
    expect(
      (await sessionRepository.activeSessionForRoutineToday(
        routineId: firstRoutine.metadata.id,
        localDate: habitarFunctionalDate(),
      ))
          ?.id,
      first.id,
    );
    expect(
      (await sessionRepository.activeSessionForRoutineToday(
        routineId: secondRoutine.metadata.id,
        localDate: habitarFunctionalDate(),
      ))
          ?.id,
      second.id,
    );
  });

  test('completing one routine keeps another routine pending today', () async {
    final routineRepository = InMemoryRoutineRepository();
    final sessionRepository = InMemoryRoutineSessionRepository();
    final profileRepository = InMemoryProfileRepository();
    final child = await profileRepository.createChildProfile(
      familyId: 'family-1',
      displayName: 'Nico',
      age: 9,
    );
    final firstRoutine = await routineRepository.createRoutine(
      profileId: child.metadata.id,
      title: 'Prepararse para la escuela',
      stepTitles: const ['Aseo', 'Vestirse', 'Mochila'],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final secondRoutine = await routineRepository.createRoutine(
      profileId: child.metadata.id,
      title: 'Leer antes de dormir',
      stepTitles: const ['Elegir libro', 'Leer', 'Guardar'],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final service = RoutineService(
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
    );

    var firstSession = await service.startExistingRoutine(
      firstRoutine,
      steps: await routineRepository.stepsForRoutine(firstRoutine.metadata.id),
    );
    for (var index = 0; index < 3; index += 1) {
      firstSession = await service.completeStep(firstSession);
    }
    final pending = await routinesForToday(
      routines: [firstRoutine, secondRoutine],
      localDate: habitarFunctionalDate(),
      loadOverrides: () async => const [],
      loadSessionToday: (routine) =>
          sessionRepository.latestSessionForRoutineDate(
        routineId: routine.metadata.id,
        localDate: habitarFunctionalDate(),
      ),
    );

    expect(pending.map((routine) => routine.metadata.id), [
      secondRoutine.metadata.id,
    ]);

    final profileService = ProfileService(
      repository: profileRepository,
      routineRepository: routineRepository,
      sessionRepository: sessionRepository,
      habitRepository: InMemoryHabitRepository(),
      progressRepository: InMemoryHabitProgressRepository(),
    );
    final summary =
        (await profileService.summariesForFamily('family-1')).single;

    expect(summary.activeRoutineTitle, secondRoutine.title);
    expect(summary.nextTaskTitle, 'Elegir libro');
    expect(summary.pendingTasks, 3);
  });

  test('daily returns tomorrow while once does not return after its day',
      () async {
    final createdAt = DateTime(2026, 1, 5, 10);
    Routine routine(RoutineRepeatPolicy policy) => Routine(
          metadata: EntityMetadata(
            id: 'routine-${policy.name}',
            createdAt: createdAt,
            updatedAt: createdAt,
            ownerId: 'adult-1',
          ),
          profileId: 'nico-child',
          title: policy.name,
          stepIds: const ['step-1', 'step-2', 'step-3'],
          repeatPolicy: policy,
        );

    final tomorrow = DateTime(2026, 1, 6, 10);

    expect(routineAppliesOnDate(routine(RoutineRepeatPolicy.daily), tomorrow),
        isTrue);
    expect(routineAppliesOnDate(routine(RoutineRepeatPolicy.once), tomorrow),
        isFalse);
  });

  test('weekly and weekdays policies use the expected weekdays', () {
    final monday = DateTime(2026, 1, 5, 10);
    final saturday = DateTime(2026, 1, 10, 10);
    final weekly = Routine(
      metadata: EntityMetadata(
        id: 'weekly',
        createdAt: monday,
        updatedAt: monday,
        ownerId: 'adult-1',
      ),
      profileId: 'nico-child',
      title: 'Weekly',
      stepIds: const ['step-1', 'step-2', 'step-3'],
      repeatPolicy: RoutineRepeatPolicy.weekly,
      weekdays: const [DateTime.saturday],
    );
    final weekdays = Routine(
      metadata: EntityMetadata(
        id: 'weekdays',
        createdAt: monday,
        updatedAt: monday,
        ownerId: 'adult-1',
      ),
      profileId: 'nico-child',
      title: 'Weekdays',
      stepIds: const ['step-1', 'step-2', 'step-3'],
      repeatPolicy: RoutineRepeatPolicy.weekdays,
      weekdays: const [],
    );

    expect(routineAppliesOnDate(weekly, monday), isFalse);
    expect(routineAppliesOnDate(weekly, saturday), isTrue);
    expect(routineAppliesOnDate(weekdays, monday), isTrue);
    expect(routineAppliesOnDate(weekdays, saturday), isFalse);
  });

  test('functional day follows America Asuncion instead of UTC midnight', () {
    final utcEarlyMorning = DateTime.utc(2026, 1, 2, 3, 30);
    final functionalDate = habitarFunctionalDate(utcEarlyMorning);

    expect(functionalDate, DateTime.utc(2026, 1, 2));
  });

  test('routine schedule distinguishes scheduled from pending', () {
    final now = DateTime(2026, 1, 5, 10);
    final routine = Routine(
      metadata: EntityMetadata(
        id: 'routine-1',
        createdAt: now,
        updatedAt: now,
        ownerId: 'adult-1',
      ),
      profileId: 'nico-child',
      title: 'Preparar un camino',
      stepIds: const ['step-1', 'step-2', 'step-3'],
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    final completedSession = RoutineSession(
      id: 'session-1',
      routine: routine,
      steps: const [],
      activeStepIndex: 0,
      startedAt: now,
      updatedAt: now,
      sessionDate: habitarFunctionalDate(now),
      status: RoutineSessionStatus.completed,
    );

    expect(routineAppliesOnDate(routine, now), isTrue);
    expect(
      routineIsPendingOnDate(
        routine,
        now,
        sessionToday: completedSession,
      ),
      isFalse,
    );
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
    final teenRequests =
        await supportRepository.requestsForProfile('nico-teen');
    final teenSession =
        await sessionRepository.activeSessionForProfile('nico-teen');

    expect(childRequests, hasLength(1));
    expect(teenRequests, isEmpty);
    expect(teenSession, isNull);
  });
}
