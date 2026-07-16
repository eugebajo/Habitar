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
}

class _FakeSupabaseAuthGateway implements SupabaseAuthGateway {
  SupabaseAuthUser? _current;
  String? lastPassword;

  @override
  Future<SupabaseAuthUser?> currentUser() async => _current;

  @override
  Future<SupabaseAuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    lastPassword = password;
    _current = SupabaseAuthUser(
      id: 'supabase-user-1',
      email: email,
      displayName: displayName,
      createdAt: DateTime.utc(2026, 7, 15),
    );
    return _current!;
  }
}
