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
  const widths = [320.0, 360.0, 393.0, 412.0];
  const textScales = [1.0, 1.3];

  for (final width in widths) {
    for (final textScale in textScales) {
      testWidgets(
        'adult home fits at ${width}px with text scale $textScale',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fixture = await _createFixture(withRoutine: true);
          await tester.pumpWidget(
            _testApp(
              initialLocation: '/dashboard',
              textScale: textScale,
              fixture: fixture,
            ),
          );
          await tester.pumpAndSettle();

          await tester.scrollUntilVisible(
            find.text('Equipo adulto'),
            300,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 12,
          );
          expect(find.text('Equipo adulto'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'progress fits at ${width}px with text scale $textScale',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fixture = await _createFixture(withRoutine: false);
          await tester.pumpWidget(
            _testApp(
              initialLocation: '/progress',
              textScale: textScale,
              fixture: fixture,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Sin progreso registrado'), findsOneWidget);
          expect(find.text('0 de 0 pasos completados'), findsOneWidget);
          await tester.drag(find.byType(ListView).first, const Offset(0, -900));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('progress counts completed sessions from today', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture =
        await _createFixture(withRoutine: true, completedRoutine: true);
    await tester.pumpWidget(
      _testApp(
        initialLocation: '/progress',
        textScale: 1,
        fixture: fixture,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 de 3 pasos completados'), findsOneWidget);
    expect(find.text('100% completado esta semana'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete action is visible and tappable at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = await _createFixture(withRoutine: true);
    await tester.pumpWidget(
      _testApp(
        initialLocation: '/routines',
        textScale: 1,
        fixture: fixture,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Eliminar').first,
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 10,
    );
    await tester.pumpAndSettle();
    expect(find.text('Eliminar'), findsWidgets);
    await tester.tap(find.text('Eliminar').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar esta rutina?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({
  required String initialLocation,
  required double textScale,
  required _LayoutFixture fixture,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const FamilyDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const AdultSectionScreen(kind: 'progress'),
        ),
      ),
      GoRoute(
        path: '/profiles',
        builder: (context, state) => const Scaffold(body: Text('Perfiles')),
      ),
      GoRoute(
        path: '/child',
        builder: (context, state) => const Scaffold(body: Text('Niño')),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Scaffold(body: Text('Ajustes')),
      ),
      GoRoute(
        path: '/stories',
        builder: (context, state) => const Scaffold(body: Text('Biblioteca')),
      ),
      GoRoute(
        path: '/routines',
        builder: (context, state) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const AdultSectionScreen(kind: 'routines'),
        ),
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

Future<_LayoutFixture> _createFixture({
  required bool withRoutine,
  bool completedRoutine = false,
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
  await adultProfileRepository.createAdultProfile(
    familyId: family.metadata.id,
    profileId: profile.metadata.id,
    displayName: 'Profesional con correo largo',
    kind: AdultProfileKind.professional,
    email: 'profesional.acompanante.con.correo.muy.largo@habitarpy.com',
    roleLabel: 'Acompañante',
  );
  await familyRepository.createAdultInvitation(
    familyId: family.metadata.id,
    email: 'invitacion.con.correo.extremadamente.largo@habitarpy.com',
    role: FamilyMemberRole.caregiver,
    invitedByUserId: 'adult-owner',
  );
  if (withRoutine) {
    final routine = await routineRepository.createRoutine(
      profileId: profile.metadata.id,
      title: 'Prepararse para la escuela',
      stepTitles: const [
        'Aseo',
        'Vestirse',
        'Mochila',
      ],
      scheduledHour: 7,
      scheduledMinute: 0,
      repeatPolicy: RoutineRepeatPolicy.daily,
    );
    if (completedRoutine) {
      final steps =
          await routineRepository.stepsForRoutine(routine.metadata.id);
      await sessionRepository.save(
        RoutineSession(
          id: 'session-completed',
          routine: routine,
          steps: steps,
          activeStepIndex: steps.length,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          sessionDate: habitarFunctionalDate(),
          status: RoutineSessionStatus.completed,
          completedStepIds:
              steps.map((step) => step.metadata.id).toList(growable: false),
          completedAt: DateTime.now(),
        ),
      );
    }
  }

  return _LayoutFixture(
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

class _LayoutFixture {
  const _LayoutFixture({
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
