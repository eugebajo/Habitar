// Covers RoutineSessionRepository.completeSession +
// FamilyActivityEventRepository consistency across the Local and InMemory
// backends (the Supabase/RPC path has its own fake-server coverage in
// supabase_routine_completion_test.dart). Both backends must: create exactly
// one event per completed session, stay idempotent on a second call, keep
// families isolated, and keep the event's snapshot text even after the
// routine is archived.

import 'dart:io';

import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_routine_engine/routine_engine.dart';
import 'package:test/test.dart';

RoutineSession _completedSession({
  required String sessionId,
  required Routine routine,
  required List<RoutineStep> steps,
}) {
  return RoutineSession(
    id: sessionId,
    routine: routine,
    steps: steps,
    activeStepIndex: steps.length,
    startedAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: RoutineSessionStatus.completed,
    completedStepIds: steps.map((s) => s.metadata.id).toList(),
    completedAt: DateTime.now(),
  );
}

void main() {
  group('InMemory backend', () {
    late InMemoryProfileRepository profileRepository;
    late InMemoryRoutineRepository routineRepository;
    late InMemoryFamilyActivityEventRepository activityEvents;
    late InMemoryRoutineSessionRepository sessionRepository;

    setUp(() {
      profileRepository = InMemoryProfileRepository();
      routineRepository = InMemoryRoutineRepository();
      activityEvents = InMemoryFamilyActivityEventRepository();
      sessionRepository = InMemoryRoutineSessionRepository(
        profileRepository: profileRepository,
        activityEvents: activityEvents,
      );
    });

    test('completing a session records exactly one event, twice does not '
        'duplicate it', () async {
      final child = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final routine = await routineRepository.createRoutine(
        profileId: child.metadata.id,
        title: 'Prepararse para la escuela',
        stepTitles: ['Vestirse', 'Desayunar', 'Mochila'],
      );
      final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
      final session = _completedSession(
          sessionId: 'session-1', routine: routine, steps: steps);

      await sessionRepository.completeSession(session);
      await sessionRepository.completeSession(session);

      expect(activityEvents.events, hasLength(1));
      final event = activityEvents.events.single;
      expect(event.familyId, 'family-a');
      expect(event.profileDisplayName, 'Nico');
      expect(event.routineTitle, 'Prepararse para la escuela');
      expect(event.kind, 'routine_completed');
    });

    test('recentEventsForFamily keeps two families isolated', () async {
      final childA = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final childB = await profileRepository.createChildProfile(
          familyId: 'family-b', displayName: 'Mia', age: 6);
      final routineA = await routineRepository.createRoutine(
        profileId: childA.metadata.id,
        title: 'Rutina A',
        stepTitles: ['Uno', 'Dos', 'Tres'],
      );
      final routineB = await routineRepository.createRoutine(
        profileId: childB.metadata.id,
        title: 'Rutina B',
        stepTitles: ['Uno', 'Dos', 'Tres'],
      );
      await sessionRepository.completeSession(_completedSession(
        sessionId: 'session-a',
        routine: routineA,
        steps: await routineRepository.stepsForRoutine(routineA.metadata.id),
      ));
      await sessionRepository.completeSession(_completedSession(
        sessionId: 'session-b',
        routine: routineB,
        steps: await routineRepository.stepsForRoutine(routineB.metadata.id),
      ));

      final familyAEvents =
          await activityEvents.recentEventsForFamily('family-a');
      expect(familyAEvents, hasLength(1));
      expect(familyAEvents.single.routineTitle, 'Rutina A');

      final familyBEvents =
          await activityEvents.recentEventsForFamily('family-b');
      expect(familyBEvents, hasLength(1));
      expect(familyBEvents.single.routineTitle, 'Rutina B');
    });

    test('archiving the routine afterwards keeps the event and its snapshot',
        () async {
      final child = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final routine = await routineRepository.createRoutine(
        profileId: child.metadata.id,
        title: 'Prepararse para la escuela',
        stepTitles: ['Vestirse', 'Desayunar', 'Mochila'],
      );
      final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
      await sessionRepository.completeSession(
          _completedSession(sessionId: 'session-1', routine: routine, steps: steps));

      await routineRepository.updateRoutineStatus(
          routine.metadata.id, EntityStatus.deleted);

      final events = await activityEvents.recentEventsForFamily('family-a');
      expect(events, hasLength(1));
      expect(events.single.routineTitle, 'Prepararse para la escuela');
    });
  });

  group('Local backend', () {
    late Directory tempDir;
    late FileLocalStore store;
    late LocalProfileRepository profileRepository;
    late LocalRoutineRepository routineRepository;
    late LocalFamilyActivityEventRepository activityEvents;
    late LocalRoutineSessionRepository sessionRepository;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('habitar_activity_event_test_');
      store = FileLocalStore(File('${tempDir.path}/habitar.json'));
      profileRepository = LocalProfileRepository(store);
      routineRepository = LocalRoutineRepository(store);
      activityEvents = LocalFamilyActivityEventRepository(store);
      sessionRepository = LocalRoutineSessionRepository(store);
    });

    tearDown(() => tempDir.delete(recursive: true));

    test('completing a session records exactly one event, twice does not '
        'duplicate it', () async {
      final child = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final routine = await routineRepository.createRoutine(
        profileId: child.metadata.id,
        title: 'Prepararse para la escuela',
        stepTitles: ['Vestirse', 'Desayunar', 'Mochila'],
      );
      final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
      final session = _completedSession(
          sessionId: 'session-1', routine: routine, steps: steps);

      await sessionRepository.completeSession(session);
      await sessionRepository.completeSession(session);

      final events = await activityEvents.recentEventsForFamily('family-a');
      expect(events, hasLength(1));
      expect(events.single.profileDisplayName, 'Nico');
      expect(events.single.routineTitle, 'Prepararse para la escuela');
    });

    test('recentEventsForFamily keeps two families isolated', () async {
      final childA = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final childB = await profileRepository.createChildProfile(
          familyId: 'family-b', displayName: 'Mia', age: 6);
      final routineA = await routineRepository.createRoutine(
        profileId: childA.metadata.id,
        title: 'Rutina A',
        stepTitles: ['Uno', 'Dos', 'Tres'],
      );
      final routineB = await routineRepository.createRoutine(
        profileId: childB.metadata.id,
        title: 'Rutina B',
        stepTitles: ['Uno', 'Dos', 'Tres'],
      );
      await sessionRepository.completeSession(_completedSession(
        sessionId: 'session-a',
        routine: routineA,
        steps: await routineRepository.stepsForRoutine(routineA.metadata.id),
      ));
      await sessionRepository.completeSession(_completedSession(
        sessionId: 'session-b',
        routine: routineB,
        steps: await routineRepository.stepsForRoutine(routineB.metadata.id),
      ));

      final familyAEvents =
          await activityEvents.recentEventsForFamily('family-a');
      expect(familyAEvents, hasLength(1));
      expect(familyAEvents.single.routineTitle, 'Rutina A');

      final familyBEvents =
          await activityEvents.recentEventsForFamily('family-b');
      expect(familyBEvents, hasLength(1));
      expect(familyBEvents.single.routineTitle, 'Rutina B');
    });

    test('archiving the routine afterwards keeps the event and its snapshot',
        () async {
      final child = await profileRepository.createChildProfile(
          familyId: 'family-a', displayName: 'Nico', age: 8);
      final routine = await routineRepository.createRoutine(
        profileId: child.metadata.id,
        title: 'Prepararse para la escuela',
        stepTitles: ['Vestirse', 'Desayunar', 'Mochila'],
      );
      final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
      await sessionRepository.completeSession(
          _completedSession(sessionId: 'session-1', routine: routine, steps: steps));

      await routineRepository.updateRoutineStatus(
          routine.metadata.id, EntityStatus.deleted);

      final events = await activityEvents.recentEventsForFamily('family-a');
      expect(events, hasLength(1));
      expect(events.single.routineTitle, 'Prepararse para la escuela');
    });
  });
}
