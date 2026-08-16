// Widget coverage for RedeemInvitationCodeScreen: the signed-out prompt,
// accepting a code straight into an empty auto-created family (no warning),
// and the leave-family warning when the caller already has profiles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/login/redeem_invitation_code_screen.dart';

void main() {
  testWidgets(
      'signed-out visitors see Crear cuenta / Ya tengo una cuenta, not the code field',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Ya tengo una cuenta'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Registro'), findsOneWidget);
  });

  testWidgets(
      'accepting a valid code from a fresh empty family skips the warning',
      (tester) async {
    final fixture = await _createFixture();
    final inviter = await fixture.authRepository.registerAdult(
      displayName: 'Dueña',
      email: 'duena@example.com',
      password: 'secret123',
    );
    final inviterFamily = await fixture.familyRepository.createFamily(
      ownerUserId: inviter.metadata.id,
      name: 'Familia que invita',
    );
    final created = await fixture.familyRepository.createInvitationWithCode(
      familyId: inviterFamily.metadata.id,
      email: 'invitado@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: inviter.metadata.id,
      invitedByUserEmail: 'duena@example.com',
    );

    // The invitee registers (their own family is auto-created, empty).
    await fixture.authRepository.registerAdult(
      displayName: 'Invitado',
      email: 'invitado@example.com',
      password: 'secret123',
    );

    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), created.code);
    await tester.tap(find.text('Aceptar invitación'));
    await tester.pumpAndSettle();

    expect(find.text('¿Aceptar esta invitación?'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'accepting a code warns before leaving a family that already has a profile',
      (tester) async {
    final fixture = await _createFixture();
    final inviter = await fixture.authRepository.registerAdult(
      displayName: 'Dueña',
      email: 'duena@example.com',
      password: 'secret123',
    );
    final inviterFamily = await fixture.familyRepository.createFamily(
      ownerUserId: inviter.metadata.id,
      name: 'Familia que invita',
    );
    final created = await fixture.familyRepository.createInvitationWithCode(
      familyId: inviterFamily.metadata.id,
      email: 'invitado@example.com',
      role: FamilyMemberRole.parent,
      invitedByUserId: inviter.metadata.id,
      invitedByUserEmail: 'duena@example.com',
    );

    // The invitee already has their own family with a child profile in it.
    final invitee = await fixture.authRepository.registerAdult(
      displayName: 'Invitado',
      email: 'invitado@example.com',
      password: 'secret123',
    );
    final owned = await fixture.familyRepository.createFamily(
      ownerUserId: invitee.metadata.id,
      name: 'Familia propia',
    );
    await fixture.profileRepository.createChildProfile(
      familyId: owned.metadata.id,
      displayName: 'Nico',
      age: 9,
    );

    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), created.code);
    await tester.tap(find.text('Aceptar invitación'));
    await tester.pumpAndSettle();

    expect(find.text('¿Aceptar esta invitación?'), findsOneWidget);
    expect(
      find.textContaining('Los perfiles y rutinas que hayas creado'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // Declining the warning must not accept the invitation nor navigate away.
    expect(find.text('Dashboard'), findsNothing);
    final members = await fixture.familyRepository
        .membersForFamily(inviterFamily.metadata.id);
    expect(members.map((m) => m.userId), isNot(contains(invitee.metadata.id)));
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({required _RedeemFixture fixture}) {
  final router = GoRouter(
    initialLocation: '/invitation/redeem',
    routes: [
      GoRoute(
        path: '/invitation/redeem',
        builder: (context, state) => const RedeemInvitationCodeScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('Registro')),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(body: Text('Dashboard')),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const Scaffold(body: Text('Onboarding')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(fixture.authRepository),
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
    ],
    child: MaterialApp.router(
      theme: buildHabitarTheme(),
      routerConfig: router,
    ),
  );
}

Future<_RedeemFixture> _createFixture() async {
  return _RedeemFixture(
    authRepository: InMemoryAuthRepository(),
    familyRepository: InMemoryFamilyRepository(),
    profileRepository: InMemoryProfileRepository(),
    routineRepository: InMemoryRoutineRepository(),
    adultProfileRepository: InMemoryAdultProfileRepository(),
    sessionRepository: InMemoryRoutineSessionRepository(),
    supportRepository: InMemorySupportRequestRepository(),
    overrideRepository: InMemoryRoutineOverrideRepository(),
  );
}

class _RedeemFixture {
  const _RedeemFixture({
    required this.authRepository,
    required this.familyRepository,
    required this.profileRepository,
    required this.routineRepository,
    required this.adultProfileRepository,
    required this.sessionRepository,
    required this.supportRepository,
    required this.overrideRepository,
  });

  final InMemoryAuthRepository authRepository;
  final InMemoryFamilyRepository familyRepository;
  final InMemoryProfileRepository profileRepository;
  final InMemoryRoutineRepository routineRepository;
  final InMemoryAdultProfileRepository adultProfileRepository;
  final InMemoryRoutineSessionRepository sessionRepository;
  final InMemorySupportRequestRepository supportRepository;
  final InMemoryRoutineOverrideRepository overrideRepository;
}
