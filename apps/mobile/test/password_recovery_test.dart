import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_application/application.dart';
import 'package:habitar_design_system/design_system.dart';
import 'package:habitar_domain/domain.dart';
import 'package:habitar_mobile/src/dependencies.dart';
import 'package:habitar_mobile/src/features/login/password_recovery_screen.dart';
import 'package:habitar_mobile/src/features/startup/startup_screen.dart';

void main() {
  testWidgets('forgot password screen returns to login when opened directly',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/recover',
      routes: [
        GoRoute(
          path: '/recover',
          builder: (context, state) => const PasswordRecoveryScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(_testApp(router: router));

    expect(find.text('Recuperar contrasena'), findsOneWidget);

    await tester.tap(find.text('Volver al inicio de sesion'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('forgot password validates email before sending', (tester) async {
    final auth = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/recover',
      routes: [
        GoRoute(
          path: '/recover',
          builder: (context, state) => const PasswordRecoveryScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_testApp(router: router, authRepository: auth));

    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();

    expect(find.text('Completa tu correo'), findsOneWidget);
    expect(auth.resetRequests, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'correo-invalido');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();

    expect(find.text('Ingresa un correo valido'), findsOneWidget);
    expect(auth.resetRequests, isEmpty);
  });

  testWidgets('forgot password sends reset link for valid email',
      (tester) async {
    final auth = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/recover',
      routes: [
        GoRoute(
          path: '/recover',
          builder: (context, state) => const PasswordRecoveryScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_testApp(router: router, authRepository: auth));
    await tester.enterText(find.byType(TextFormField), 'adulto@example.com');
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    expect(auth.resetRequests.single.email, 'adulto@example.com');
    expect(
      auth.resetRequests.single.redirectTo,
      Uri.parse('com.habitarpy.app://reset-password'),
    );
    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(
      find.text('Te enviamos un enlace para crear una nueva contrasena.'),
      findsOneWidget,
    );
  });

  testWidgets('reset password route updates password', (tester) async {
    final auth = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_testApp(router: router, authRepository: auth));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nueva contrasena'),
      'nueva-clave',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contrasena'),
      'nueva-clave',
    );
    await tester.tap(find.text('Guardar contrasena'));
    await tester.pumpAndSettle();

    expect(auth.updatedPasswords.single, 'nueva-clave');
    expect(find.text('Contrasena actualizada'), findsOneWidget);
  });

  testWidgets('password recovery has priority over normal restore redirect',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const StartupScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        router: router,
        recoveryActive: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear nueva contrasena'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  test('password recovery redirect uses web URL on habitarpy.com', () {
    final redirect = passwordRecoveryRedirectUri(
      isWebOverride: true,
      baseUri: Uri.parse('https://habitarpy.com/app/'),
    );

    expect(
      redirect,
      Uri.parse('https://habitarpy.com/app/#/reset-password'),
    );
  });

  test('password recovery redirect uses app URL on Android release', () {
    final redirect = passwordRecoveryRedirectUri(isWebOverride: false);

    expect(redirect.scheme, 'com.habitarpy.app');
    expect(redirect.host, 'reset-password');
  });
}

Widget _testApp({
  required GoRouter router,
  AuthRepository? authRepository,
  bool recoveryActive = false,
}) {
  return ProviderScope(
    overrides: [
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      passwordRecoveryActiveProvider.overrideWith((ref) => recoveryActive),
    ],
    child: MaterialApp.router(
      theme: buildHabitarTheme(),
      routerConfig: router,
    ),
  );
}

class _ResetRequest {
  const _ResetRequest({required this.email, required this.redirectTo});

  final String email;
  final Uri redirectTo;
}

class _FakeAuthRepository implements AuthRepository {
  final resetRequests = <_ResetRequest>[];
  final updatedPasswords = <String>[];

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<User> registerAdult({
    required String displayName,
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required Uri redirectTo,
  }) async {
    resetRequests.add(_ResetRequest(email: email, redirectTo: redirectTo));
  }

  @override
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updatePassword({required String password}) async {
    updatedPasswords.add(password);
  }
}
