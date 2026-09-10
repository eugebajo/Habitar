// Widget coverage for the "your family was deleted" notice shown on
// startup (StartupScreen._showDepartureNotices): the notice is shown once,
// with a human message and no data about a child, its row is dismissed
// right after being shown, and the "create a new space" option actually
// creates a family for the already signed-in adult instead of routing
// through the sign-up-only /register screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/app.dart';
import 'package:habitar_mobile/src/dependencies.dart';

void main() {
  // appRouter is a module-level singleton (see app.dart) - its current
  // location survives between tests in this same file even though each
  // test builds a fresh ProviderScope. Without resetting it, a later test
  // would start on whatever route the previous one navigated to, never
  // reaching StartupScreen and never triggering a departure-notice check.
  setUp(() => appRouter.go('/'));

  testWidgets(
      'a departure notice shows the family name, dismisses on "Entendido" and sends the adult to register',
      (tester) async {
    final fixture = await _seedDepartedAdult();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fixture.authRepository),
          familyRepositoryProvider.overrideWithValue(fixture.familyRepository),
        ],
        child: const HabitarMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu espacio familiar ya no está'), findsOneWidget);
    expect(find.textContaining('Familia Test'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();

    // No "create new" chosen: restore's normal destination for a
    // signed-in adult without a family takes over - the sign-up screen.
    expect(find.text('Contame quien sostiene este espacio.'), findsOneWidget);

    final remainingNotices = await fixture.familyRepository
        .departureNotices(fixture.invited.metadata.id);
    expect(remainingNotices, isEmpty);
  });

  testWidgets(
      '"Crear un nuevo espacio" creates a family for the signed-in adult without going through sign-up',
      (tester) async {
    final fixture = await _seedDepartedAdult();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fixture.authRepository),
          familyRepositoryProvider.overrideWithValue(fixture.familyRepository),
        ],
        child: const HabitarMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Crear un nuevo espacio'));
    await tester.pumpAndSettle();

    expect(find.text('Nombrá tu nuevo espacio'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Nuevo espacio');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    // Landed on profile setup - a real family was created, not a bounce
    // through the sign-up-only /register screen.
    expect(find.text('¿Quién usará Habitar?'), findsOneWidget);

    final newFamily =
        await fixture.familyRepository.currentFamily(fixture.invited.metadata.id);
    expect(newFamily?.name, 'Nuevo espacio');

    final remainingNotices = await fixture.familyRepository
        .departureNotices(fixture.invited.metadata.id);
    expect(remainingNotices, isEmpty);
  });
}

class _DepartedAdultFixture {
  const _DepartedAdultFixture({
    required this.authRepository,
    required this.familyRepository,
    required this.invited,
  });

  final InMemoryAuthRepository authRepository;
  final InMemoryFamilyRepository familyRepository;
  final User invited;
}

/// Builds a family with an owner and a second adult, then has the owner
/// delete the family (same as tapping "Eliminar todo el espacio familiar"
/// in AccountScreen) - which leaves the second adult with a
/// FamilyDepartureNotice and no family, signed back in as themselves, the
/// way they'd find the app the next time they open it.
Future<_DepartedAdultFixture> _seedDepartedAdult() async {
  final authRepository = InMemoryAuthRepository();
  final familyRepository = InMemoryFamilyRepository();

  final owner = await authRepository.registerAdult(
    displayName: 'Dueña',
    email: 'duena@example.com',
    password: 'secret123',
  );
  final family = await familyRepository.createFamily(
    ownerUserId: owner.metadata.id,
    name: 'Familia Test',
  );
  final created = await familyRepository.createInvitationWithCode(
    familyId: family.metadata.id,
    email: 'invitado@example.com',
    role: FamilyMemberRole.parent,
    invitedByUserId: owner.metadata.id,
    invitedByUserEmail: owner.email,
  );
  final invited = await authRepository.registerAdult(
    displayName: 'Invitado',
    email: 'invitado@example.com',
    password: 'secret123',
  );
  await familyRepository.acceptInvitationByCode(
    code: created.code,
    userId: invited.metadata.id,
    userEmail: invited.email,
  );

  await authRepository.signIn(email: owner.email, password: 'secret123');
  await familyRepository.deleteFamily(
    familyId: family.metadata.id,
    userId: owner.metadata.id,
  );

  // The invited adult opens the app next - still signed in on their own
  // device, family gone.
  await authRepository.signIn(email: invited.email, password: 'secret123');

  return _DepartedAdultFixture(
    authRepository: authRepository,
    familyRepository: familyRepository,
    invited: invited,
  );
}
