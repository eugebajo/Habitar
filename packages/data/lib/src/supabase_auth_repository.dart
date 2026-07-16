import 'package:habitar_application/application.dart';
import 'package:habitar_domain/domain.dart';

abstract interface class SupabaseAuthGateway {
  Future<SupabaseAuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<SupabaseAuthUser> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<SupabaseAuthUser?> currentUser();
}

class SupabaseAuthUser {
  const SupabaseAuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
}

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this.gateway);

  final SupabaseAuthGateway gateway;

  @override
  Future<User?> currentUser() async {
    final user = await gateway.currentUser();
    return user == null ? null : _mapUser(user);
  }

  @override
  Future<User> registerAdult({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final user = await gateway.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _mapUser(user);
  }

  @override
  Future<User> signIn({required String email, required String password}) async {
    final user = await gateway.signInWithPassword(
      email: email,
      password: password,
    );
    return _mapUser(user);
  }

  @override
  Future<void> signOut() {
    return gateway.signOut();
  }

  User _mapUser(SupabaseAuthUser user) {
    return User(
      metadata: EntityMetadata(
        id: user.id,
        createdAt: user.createdAt,
        updatedAt: user.createdAt,
        ownerId: user.id,
      ),
      displayName: user.displayName,
      email: user.email,
    );
  }
}
