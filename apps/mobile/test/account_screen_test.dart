// Widget coverage for AccountScreen: the three irreversible flows (delete
// my account, delete the whole family, transfer ownership), the
// re-authentication dialog they all go through, and how a
// FamilyLifecycleException from any of them is handled - both the specific
// OWNER_MUST_TRANSFER_OR_DELETE_FAMILY recovery dialog and the generic
// friendly-message fallback for every other code.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;

import 'package:habitar_data/data.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/features/account/account_screen.dart';
import 'package:habitar_mobile/src/dependencies.dart';

void main() {
  testWidgets('Account screen shows account actions for owner', (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(displayName: 'Owner', email: 'owner@example.com', password: 'pass');
    final familyRepo = InMemoryFamilyRepository();
    final family = await familyRepo.createFamily(ownerUserId: user.metadata.id, name: 'Test Family');

    await _pumpAccountScreen(tester, auth: auth, familyRepo: familyRepo, familyId: family.metadata.id);

    expect(find.text('Eliminar mi cuenta'), findsOneWidget);
  });

  testWidgets('canceling the reauth dialog does nothing', (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
      displayName: 'Sola', email: 'sola@example.com', password: 'secret123');
    final familyRepo = InMemoryFamilyRepository();
    final family = await familyRepo.createFamily(ownerUserId: user.metadata.id, name: 'Sola Family');

    await _pumpAccountScreen(tester, auth: auth, familyRepo: familyRepo, familyId: family.metadata.id);

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar mi cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmá con tu contraseña'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Confirmá con tu contraseña'), findsNothing);
    expect(find.text('Cuenta eliminada'), findsNothing);
    final stillThere = await familyRepo.membersForFamily(family.metadata.id);
    expect(stillThere, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deleting the account as the sole adult deletes the family too',
      (tester) async {
    final auth = InMemoryAuthRepository();
    final user = await auth.registerAdult(
      displayName: 'Sola', email: 'sola@example.com', password: 'secret123');
    final familyRepo = InMemoryFamilyRepository();
    final family = await familyRepo.createFamily(ownerUserId: user.metadata.id, name: 'Sola Family');

    await _pumpAccountScreen(tester, auth: auth, familyRepo: familyRepo, familyId: family.metadata.id);

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar mi cuenta'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta eliminada'), findsOneWidget);
    final remainingMembers = await familyRepo.membersForFamily(family.metadata.id);
    expect(remainingMembers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deleting the account as owner with other adults offers transfer-or-delete, and "Transferir mi rol" completes the transfer',
      (tester) async {
    final fixture = await _twoAdultFamily();

    await _pumpAccountScreen(
      tester,
      auth: fixture.authRepository,
      familyRepo: fixture.familyRepository,
      familyId: fixture.family.metadata.id,
    );

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar mi cuenta'));
    await tester.pumpAndSettle();

    // First reauth: deleteMyAccount rejects with
    // OWNER_MUST_TRANSFER_OR_DELETE_FAMILY.
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Antes de eliminar tu cuenta'), findsOneWidget);
    await tester.tap(find.text('Transferir mi rol'));
    await tester.pumpAndSettle();

    // The member list behind the dialog already shows this same email, so
    // scope the finder to the SimpleDialogOption to avoid ambiguity.
    expect(find.widgetWithText(SimpleDialogOption, fixture.other.email), findsOneWidget);
    await tester.tap(find.widgetWithText(SimpleDialogOption, fixture.other.email));
    await tester.pumpAndSettle();

    // Second reauth: for the transfer itself.
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Propiedad transferida'), findsOneWidget);
    final members = await fixture.familyRepository.membersForFamily(fixture.family.metadata.id);
    final ownerNow = members.firstWhere((m) => m.userId == fixture.other.metadata.id);
    final ownerBefore = members.firstWhere((m) => m.userId == fixture.owner.metadata.id);
    expect(ownerNow.role, FamilyMemberRole.owner);
    expect(ownerBefore.role, FamilyMemberRole.parent);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'deleting the account as owner with other adults, then "Eliminar toda la familia" deletes it and notifies the other adult',
      (tester) async {
    final fixture = await _twoAdultFamily();

    await _pumpAccountScreen(
      tester,
      auth: fixture.authRepository,
      familyRepo: fixture.familyRepository,
      familyId: fixture.family.metadata.id,
    );

    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, eliminar mi cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Antes de eliminar tu cuenta'), findsOneWidget);
    await tester.tap(find.text('Eliminar toda la familia'));
    await tester.pumpAndSettle();

    expect(find.textContaining(fixture.other.email), findsWidgets);
    await tester.tap(find.text('Eliminar familia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Familia eliminada'), findsOneWidget);
    final remainingMembers = await fixture.familyRepository.membersForFamily(fixture.family.metadata.id);
    expect(remainingMembers, isEmpty);
    final notices = await fixture.familyRepository.departureNotices(fixture.other.metadata.id);
    expect(notices, hasLength(1));
    expect(notices.single.familyName, fixture.family.name);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the "Eliminar todo el espacio familiar" button deletes the family directly',
      (tester) async {
    final fixture = await _twoAdultFamily();

    await _pumpAccountScreen(
      tester,
      auth: fixture.authRepository,
      familyRepo: fixture.familyRepository,
      familyId: fixture.family.metadata.id,
    );

    await tester.tap(find.text('Eliminar todo el espacio familiar'));
    await tester.pumpAndSettle();
    expect(find.textContaining(fixture.other.email), findsWidgets);
    await tester.tap(find.text('Eliminar familia'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Familia eliminada'), findsOneWidget);
    final notices = await fixture.familyRepository.departureNotices(fixture.other.metadata.id);
    expect(notices, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the "Transferir mi rol de dueño/a" button transfers ownership directly',
      (tester) async {
    final fixture = await _twoAdultFamily();

    await _pumpAccountScreen(
      tester,
      auth: fixture.authRepository,
      familyRepo: fixture.familyRepository,
      familyId: fixture.family.metadata.id,
    );

    await tester.tap(find.text('Transferir mi rol de dueño/a'));
    await tester.pumpAndSettle();
    // The member list behind the dialog already shows this same email, so
    // scope the finder to the SimpleDialogOption to avoid ambiguity.
    await tester.tap(find.widgetWithText(SimpleDialogOption, fixture.other.email));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Propiedad transferida'), findsOneWidget);
    final members = await fixture.familyRepository.membersForFamily(fixture.family.metadata.id);
    expect(
      members.firstWhere((m) => m.userId == fixture.other.metadata.id).role,
      FamilyMemberRole.owner,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a generic FamilyLifecycleException (e.g. a concurrent transfer already happened) shows a friendly message instead of crashing',
      (tester) async {
    final fixture = await _twoAdultFamily();

    await _pumpAccountScreen(
      tester,
      auth: fixture.authRepository,
      familyRepo: fixture.familyRepository,
      familyId: fixture.family.metadata.id,
    );

    await tester.tap(find.text('Transferir mi rol de dueño/a'));
    await tester.pumpAndSettle();
    // The member list behind the dialog already shows this same email, so
    // scope the finder to the SimpleDialogOption to avoid ambiguity.
    await tester.tap(find.widgetWithText(SimpleDialogOption, fixture.other.email));
    await tester.pumpAndSettle();

    // Simulate a concurrent transfer that already completed elsewhere while
    // this dialog was open: the owner is no longer 'owner' by the time this
    // screen's own reauth confirms, so the RPC now rejects with
    // TRANSFER_FORBIDDEN instead of the happy path.
    await fixture.familyRepository.transferFamilyOwnership(
      userId: fixture.owner.metadata.id,
      newOwnerUserId: fixture.other.metadata.id,
    );

    await tester.enterText(find.byType(TextField), 'secret123');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Propiedad transferida'), findsNothing);
    expect(
      find.text('Solo quien es dueño/a de la familia puede transferir su rol.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TwoAdultFamily {
  const _TwoAdultFamily({
    required this.authRepository,
    required this.familyRepository,
    required this.family,
    required this.owner,
    required this.other,
  });

  final InMemoryAuthRepository authRepository;
  final InMemoryFamilyRepository familyRepository;
  final Family family;
  final User owner;
  final User other;
}

Future<_TwoAdultFamily> _twoAdultFamily() async {
  final authRepository = InMemoryAuthRepository();
  final familyRepository = InMemoryFamilyRepository();
  final owner = await authRepository.registerAdult(
    displayName: 'Dueña', email: 'duena@example.com', password: 'secret123');
  final family = await familyRepository.createFamily(
      ownerUserId: owner.metadata.id, name: 'Familia con dos adultos');
  final created = await familyRepository.createInvitationWithCode(
    familyId: family.metadata.id,
    email: 'otro@example.com',
    role: FamilyMemberRole.parent,
    invitedByUserId: owner.metadata.id,
    invitedByUserEmail: owner.email,
  );
  final other = await authRepository.registerAdult(
      displayName: 'Otro Adulto', email: 'otro@example.com', password: 'secret123');
  await familyRepository.acceptInvitationByCode(
    code: created.code,
    userId: other.metadata.id,
    userEmail: other.email,
  );
  // Back to the owner - AccountScreen reads the currently signed-in user.
  await authRepository.signIn(email: owner.email, password: 'secret123');

  return _TwoAdultFamily(
    authRepository: authRepository,
    familyRepository: familyRepository,
    family: family,
    owner: owner,
    other: other,
  );
}

Future<void> _pumpAccountScreen(
  WidgetTester tester, {
  required InMemoryAuthRepository auth,
  required InMemoryFamilyRepository familyRepo,
  required String familyId,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        familyRepositoryProvider.overrideWithValue(familyRepo),
        currentFamilyIdProvider.overrideWith((ref) => familyId),
      ],
      child: const MaterialApp(home: AccountScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
