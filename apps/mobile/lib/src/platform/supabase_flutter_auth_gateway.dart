import 'package:habitar_data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FlutterSupabaseAuthGateway implements SupabaseAuthGateway {
  const FlutterSupabaseAuthGateway(this.client);

  final supabase.SupabaseClient client;

  @override
  Future<SupabaseAuthUser?> currentUser() async {
    final user = client.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<SupabaseAuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Supabase did not return a user after sign up.');
    }
    return _mapUser(user);
  }

  SupabaseAuthUser _mapUser(supabase.User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName =
        metadata['display_name'] as String? ?? user.email ?? 'Adulto';
    final createdAt =
        DateTime.tryParse(user.createdAt)?.toUtc() ?? DateTime.now().toUtc();
    return SupabaseAuthUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      createdAt: createdAt,
    );
  }
}
