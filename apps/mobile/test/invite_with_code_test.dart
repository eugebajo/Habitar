// Widget coverage for the "invite adult" flow in family_dashboard_screen.dart:
// generating a code shows the code card with working Copiar/Compartir
// actions, and a canceled invitation shows up with its real status.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/family_dashboard/family_dashboard_screen.dart';

void main() {
  // flutter_test has no built-in mock for the clipboard platform channel in
  // this SDK, so Clipboard.setData would otherwise throw a
  // MissingPluginException when the "Copiar" button is tapped.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      return null;
    });
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
      'generating an invitation code shows the code card with Copiar and Compartir',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Invitar'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invitar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'invitado@example.com',
    );
    await tester.tap(find.text('Generar código'));
    await tester.pumpAndSettle();

    expect(find.text('Código generado'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);

    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(find.text('Copiado'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a self-invitation attempt shows an inline error, not a crash',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Invitar'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invitar'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      fixture.ownerEmail,
    );
    await tester.tap(find.text('Generar código'));
    await tester.pumpAndSettle();

    expect(find.text('No podés invitarte a vos misma/o.'), findsOneWidget);
    expect(find.text('Código generado'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canceling a pending invitation updates its shown status',
      (tester) async {
    final fixture = await _createFixture();
    await tester.pumpWidget(_testApp(fixture: fixture));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Invitar'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invitar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'invitado@example.com',
    );
    await tester.tap(find.text('Generar código'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cancelar').first,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 12,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Cancelada'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp({required _InviteFixture fixture}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const FamilyDashboardScreen(),
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
      authRepositoryProvider.overrideWithValue(fixture.authRepository),
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

Future<_InviteFixture> _createFixture() async {
  final familyRepository = InMemoryFamilyRepository();
  final profileRepository = InMemoryProfileRepository();
  final routineRepository = InMemoryRoutineRepository();
  final adultProfileRepository = InMemoryAdultProfileRepository();
  final sessionRepository = InMemoryRoutineSessionRepository();
  final supportRepository = InMemorySupportRequestRepository();
  final overrideRepository = InMemoryRoutineOverrideRepository();
  final authRepository = InMemoryAuthRepository();

  const ownerEmail = 'duena@example.com';
  final owner = await authRepository.registerAdult(
    displayName: 'Dueña',
    email: ownerEmail,
    password: 'secret123',
  );
  final family = await familyRepository.createFamily(
    ownerUserId: owner.metadata.id,
    name: 'Familia de prueba',
  );
  final profile = await profileRepository.createChildProfile(
    familyId: family.metadata.id,
    displayName: 'Nico',
    age: 9,
  );

  return _InviteFixture(
    familyId: family.metadata.id,
    profileId: profile.metadata.id,
    ownerEmail: ownerEmail,
    familyRepository: familyRepository,
    profileRepository: profileRepository,
    routineRepository: routineRepository,
    adultProfileRepository: adultProfileRepository,
    sessionRepository: sessionRepository,
    supportRepository: supportRepository,
    overrideRepository: overrideRepository,
    authRepository: authRepository,
  );
}

class _InviteFixture {
  const _InviteFixture({
    required this.familyId,
    required this.profileId,
    required this.ownerEmail,
    required this.familyRepository,
    required this.profileRepository,
    required this.routineRepository,
    required this.adultProfileRepository,
    required this.sessionRepository,
    required this.supportRepository,
    required this.overrideRepository,
    required this.authRepository,
  });

  final String familyId;
  final String profileId;
  final String ownerEmail;
  final InMemoryFamilyRepository familyRepository;
  final InMemoryProfileRepository profileRepository;
  final InMemoryRoutineRepository routineRepository;
  final InMemoryAdultProfileRepository adultProfileRepository;
  final InMemoryRoutineSessionRepository sessionRepository;
  final InMemorySupportRequestRepository supportRepository;
  final InMemoryRoutineOverrideRepository overrideRepository;
  final InMemoryAuthRepository authRepository;
}
