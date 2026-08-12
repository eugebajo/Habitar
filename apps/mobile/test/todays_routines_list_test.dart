// Regression coverage: a profile with more than one pending routine for
// today used to only ever see the first one (both on the child's home
// screen and on the adult's Inicio dashboard), because both screens picked
// `todaysRoutines.first` and discarded the rest.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/family_dashboard/family_dashboard_screen.dart';
import 'package:habitar_mobile/src/features/portal/portal_screens.dart';
import 'package:habitar_routine_engine/routine_engine.dart';

void main() {
  testWidgets(
      'ChildHomeScreen shows both pending routines when a profile has two',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(
      initialLocation: '/child',
      fixture: fixture,
    ));
    await tester.pumpAndSettle();

    // The earliest-scheduled routine is the highlighted "Ahora" card.
    expect(find.text('Prepararse para la escuela'), findsOneWidget);
    // The second pending routine still shows up, in the simpler list below,
    // with its own "Empezar" action (the other "Empezar" is the highlighted
    // "Ahora" card's own action button).
    expect(find.text('Leer antes de dormir'), findsOneWidget);
    expect(find.text('Empezar'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'ChildHomeScreen only shows the highlighted routine when just one is pending',
      (tester) async {
    final fixture = await _createFixture(secondRoutine: false);
    await tester.pumpWidget(_testApp(
      initialLocation: '/child',
      fixture: fixture,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Prepararse para la escuela'), findsOneWidget);
    expect(find.text('Más para hoy'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Adult Inicio dashboard shows both pending routines with their own progress',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(
      initialLocation: '/dashboard',
      fixture: fixture,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Prepararse para la escuela'), findsOneWidget);
    expect(find.text('Leer antes de dormir'), findsOneWidget);
    expect(find.text('Recordar'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Adult Inicio dashboard keeps the "todo completado" state',
      (tester) async {
    final fixture = await _createFixture(completeAll: true);
    await tester.pumpWidget(_testApp(
      initialLocation: '/dashboard',
      fixture: fixture,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Todo completado'), findsOneWidget);
    expect(find.text('Rutinas completadas'), findsOneWidget);
    expect(find.text('Recordar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required String initialLocation,
  required _TodayFixture fixture,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const FamilyDashboardScreen(),
      ),
      GoRoute(
        path: '/child',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const Scaffold(body: Text('Perfiles')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/child/emotions',
        builder: (context, state) => const Scaffold(body: Text('Emociones')),
      ),
      GoRoute(
        path: '/routine/player',
        builder: (context, state) => const Scaffold(body: Text('Rutina')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      familyRepositoryProvider.overrideWithValue(fixture.familyRepository),
      profileRepositoryProvider.overrideWithValue(fixture.profileRepository),
      routineRepositoryProvider.overrideWithValue(fixture.routineRepository),
      adultProfileRepositoryProvider
          .overrideWithValue(fixture.adultProfileRepository),
      routineSessionRepositoryProvider
          .overrideWithValue(fixture.sessionRepository),
      supportRequestRepositoryProvider
          .overrideWithValue(fixture.supportRepository),
      routineOverrideRepositoryProvider
          .overrideWithValue(fixture.overrideRepository),
      currentFamilyIdProvider.overrideWith((ref) => fixture.familyId),
      currentProfileIdProvider.overrideWith((ref) => fixture.profileId),
      currentProfileKindProvider.overrideWith((ref) => ProfileKind.child),
    ],
    child: MaterialApp.router(
      theme: buildHabitarTheme(),
      routerConfig: router,
    ),
  );
}

/// Creates a child profile with two routines scheduled for today (unless
/// [secondRoutine] is false), each with three steps and no started session,
/// so both are pending. With [completeAll], both are marked completed today
/// instead, to make sure the "everything done" state still shows up when
/// there's more than one routine.
Future<_TodayFixture> _createFixture({
  bool secondRoutine = true,
  bool completeAll = false,
}) async {
  final familyRepository = InMemoryFamilyRepository();
  final profileRepository = InMemoryProfileRepository();
  final routineRepository = InMemoryRoutineRepository();
  final adultProfileRepository = InMemoryAdultProfileRepository();
  final sessionRepository = InMemoryRoutineSessionRepository();
  final supportRepository = InMemorySupportRequestRepository();
  final overrideRepository = InMemoryRoutineOverrideRepository();

  final family = await familyRepository.createFamily(
    ownerUserId: 'adult-owner',
    name: 'Familia de prueba',
  );
  final profile = await profileRepository.createChildProfile(
    familyId: family.metadata.id,
    displayName: 'Nico',
    age: 9,
  );

  final firstRoutine = await routineRepository.createRoutine(
    profileId: profile.metadata.id,
    title: 'Prepararse para la escuela',
    stepTitles: const ['Aseo', 'Vestirse', 'Mochila'],
    scheduledHour: 7,
    scheduledMinute: 0,
    repeatPolicy: RoutineRepeatPolicy.daily,
  );

  if (completeAll) {
    await _completeRoutine(sessionRepository, routineRepository, firstRoutine);
  }

  if (secondRoutine) {
    final routine = await routineRepository.createRoutine(
      profileId: profile.metadata.id,
      title: 'Leer antes de dormir',
      stepTitles: const ['Elegir libro', 'Leer', 'Guardar'],
      scheduledHour: 20,
      scheduledMinute: 0,
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    if (completeAll) {
      await _completeRoutine(sessionRepository, routineRepository, routine);
    }
  }

  return _TodayFixture(
    familyId: family.metadata.id,
    profileId: profile.metadata.id,
    familyRepository: familyRepository,
    profileRepository: profileRepository,
    routineRepository: routineRepository,
    adultProfileRepository: adultProfileRepository,
    sessionRepository: sessionRepository,
    supportRepository: supportRepository,
    overrideRepository: overrideRepository,
  );
}

Future<void> _completeRoutine(
  InMemoryRoutineSessionRepository sessionRepository,
  InMemoryRoutineRepository routineRepository,
  Routine routine,
) async {
  final steps = await routineRepository.stepsForRoutine(routine.metadata.id);
  final now = DateTime.now();
  await sessionRepository.save(
    RoutineSession(
      id: 'session-${routine.metadata.id}',
      routine: routine,
      steps: steps,
      activeStepIndex: steps.length,
      startedAt: now,
      updatedAt: now,
      sessionDate: habitarFunctionalDate(),
      status: RoutineSessionStatus.completed,
      completedStepIds:
          steps.map((step) => step.metadata.id).toList(growable: false),
      completedAt: now,
    ),
  );
}

class _TodayFixture {
  const _TodayFixture({
    required this.familyId,
    required this.profileId,
    required this.familyRepository,
    required this.profileRepository,
    required this.routineRepository,
    required this.adultProfileRepository,
    required this.sessionRepository,
    required this.supportRepository,
    required this.overrideRepository,
  });

  final String familyId;
  final String profileId;
  final InMemoryFamilyRepository familyRepository;
  final InMemoryProfileRepository profileRepository;
  final InMemoryRoutineRepository routineRepository;
  final InMemoryAdultProfileRepository adultProfileRepository;
  final InMemoryRoutineSessionRepository sessionRepository;
  final InMemorySupportRequestRepository supportRepository;
  final InMemoryRoutineOverrideRepository overrideRepository;
}
