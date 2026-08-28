import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_data/data.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/adult_registration/adult_registration_screen.dart';

void main() {
  testWidgets(
      'tapping the registration button calls registerAdult (signUp) and never signIn',
      (tester) async {
    final auth = _CallTrackingAuthRepository();
    final router = GoRouter(
      initialLocation: '/register',
      routes: [
        GoRoute(
          path: '/register',
          builder: (context, state) => const AdultRegistrationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('Profile')),
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          familyRepositoryProvider.overrideWithValue(InMemoryFamilyRepository()),
        ],
        child: MaterialApp.router(
          theme: buildHabitarTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Ana',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Familia Ana',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'ana@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'clave-segura',
    );

    await tester.tap(find.text('Seguir con mi familia'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, isEmpty,
        reason:
            'El boton de registro nunca debe llamar a signIn/signInWithPassword.');
    expect(auth.registerCalls, hasLength(1));
    expect(auth.registerCalls.single.email, 'ana@example.com');
    expect(auth.registerCalls.single.password, 'clave-segura');
    expect(find.text('Profile'), findsOneWidget);
  });
}

class _RegisterCall {
  const _RegisterCall(
      {required this.displayName,
      required this.email,
      required this.password});

  final String displayName;
  final String email;
  final String password;
}

class _SignInCall {
  const _SignInCall({required this.email, required this.password});

  final String email;
  final String password;
}

class _CallTrackingAuthRepository implements AuthRepository {
  final registerCalls = <_RegisterCall>[];
  final signInCalls = <_SignInCall>[];

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User> registerAdult({
    required String displayName,
    required String email,
    required String password,
  }) async {
    registerCalls.add(_RegisterCall(
      displayName: displayName,
      email: email,
      password: password,
    ));
    final now = DateTime.now().toUtc();
    return User(
      metadata: EntityMetadata(
        id: 'user-1',
        createdAt: now,
        updatedAt: now,
        ownerId: 'user-1',
      ),
      displayName: displayName,
      email: email,
    );
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls.add(_SignInCall(email: email, password: password));
    throw StateError(
      'signIn/signInWithPassword must not be called from the registration screen.',
    );
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({
    required String email,
    required Uri redirectTo,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword({required String password}) async {
    throw UnimplementedError();
  }
}
