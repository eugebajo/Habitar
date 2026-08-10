import 'package:habitar_data/data.dart';
import 'package:test/test.dart';

void main() {
  test('maps Supabase sign up user into domain user', () async {
    final gateway = _FakeSupabaseAuthGateway();
    final repository = SupabaseAuthRepository(gateway);

    final user = await repository.registerAdult(
      displayName: 'Adulto',
      email: 'adulto@example.com',
      password: 'secret',
    );

    expect(user.metadata.id, 'supabase-user-1');
    expect(user.metadata.ownerId, 'supabase-user-1');
    expect(user.email, 'adulto@example.com');
    expect(gateway.lastPassword, 'secret');
  });

  test('surfaces email confirmation requirement without a session', () async {
    final gateway =
        _FakeSupabaseAuthGateway(requireEmailConfirmation: true);
    final repository = SupabaseAuthRepository(gateway);

    await expectLater(
      repository.registerAdult(
        displayName: 'Adulto',
        email: 'adulto@example.com',
        password: 'secret',
      ),
      throwsA(isA<EmailConfirmationRequiredException>()),
    );

    expect(gateway.lastPassword, 'secret');
    expect(await repository.currentUser(), isNull);
  });

  test('maps current Supabase user when available', () async {
    final gateway = _FakeSupabaseAuthGateway();
    final repository = SupabaseAuthRepository(gateway);

    expect(await repository.currentUser(), isNull);

    await repository.registerAdult(
      displayName: 'Adulto',
      email: 'adulto@example.com',
      password: 'secret',
    );

    expect((await repository.currentUser())?.displayName, 'Adulto');
  });

  test('signs in and signs out through Supabase gateway', () async {
    final gateway = _FakeSupabaseAuthGateway();
    final repository = SupabaseAuthRepository(gateway);

    final user = await repository.signIn(
      email: 'adulto@example.com',
      password: 'secret',
    );

    expect(user.email, 'adulto@example.com');
    expect(gateway.lastPassword, 'secret');
    expect((await repository.currentUser())?.metadata.id, 'supabase-user-1');

    await repository.signOut();

    expect(await repository.currentUser(), isNull);
  });

  test('requests password reset through Supabase gateway', () async {
    final gateway = _FakeSupabaseAuthGateway();
    final repository = SupabaseAuthRepository(gateway);
    final redirectTo = Uri.parse('https://habitarpy.com/app/#/reset-password');

    await repository.requestPasswordReset(
      email: 'adulto@example.com',
      redirectTo: redirectTo,
    );

    expect(gateway.lastResetEmail, 'adulto@example.com');
    expect(gateway.lastResetRedirectTo, redirectTo);
  });

  test('updates password through Supabase gateway', () async {
    final gateway = _FakeSupabaseAuthGateway();
    final repository = SupabaseAuthRepository(gateway);

    await repository.updatePassword(password: 'new-secret');

    expect(gateway.lastUpdatedPassword, 'new-secret');
  });
}

class _FakeSupabaseAuthGateway implements SupabaseAuthGateway {
  _FakeSupabaseAuthGateway({this.requireEmailConfirmation = false});

  final bool requireEmailConfirmation;
  SupabaseAuthUser? _current;
  String? lastPassword;
  String? lastResetEmail;
  Uri? lastResetRedirectTo;
  String? lastUpdatedPassword;

  @override
  Future<SupabaseAuthUser?> currentUser() async => _current;

  @override
  Future<SupabaseAuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    lastPassword = password;
    if (requireEmailConfirmation) {
      throw EmailConfirmationRequiredException(email);
    }
    _current = SupabaseAuthUser(
      id: 'supabase-user-1',
      email: email,
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 15),
    );
    return _current!;
  }

  @override
  Future<SupabaseAuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    lastPassword = password;
    _current = SupabaseAuthUser(
      id: 'supabase-user-1',
      email: email,
      displayName: 'Adulto',
      createdAt: DateTime.utc(2026, 7, 15),
    );
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    required Uri redirectTo,
  }) async {
    lastResetEmail = email;
    lastResetRedirectTo = redirectTo;
  }

  @override
  Future<void> updatePassword({required String password}) async {
    lastUpdatedPassword = password;
  }
}
