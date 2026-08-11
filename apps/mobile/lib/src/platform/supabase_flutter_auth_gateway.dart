import 'package:habitar_data/data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_diagnostics.dart';

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
      _debugLog('AUTH SIGNUP: ERROR user_null');
      throw StateError('No pudimos crear el usuario.');
    }
    _debugLog('AUTH SIGNUP: OK');
    _debugLog(
      'SESSION AFTER SIGNUP: ${response.session == null ? 'NULL' : 'PRESENT'}',
    );
    if (response.session == null) {
      throw EmailConfirmationRequiredException(email);
    }
    return _mapUser(user);
  }

  @override
  Future<SupabaseAuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      _debugLog('AUTH LOGIN:');
      _debugLog('email_present: ${normalizedEmail.isNotEmpty}');
      final response = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        _debugLog('AUTH LOGIN RESULT: ERROR');
        _debugLog('AuthException statusCode: null');
        _debugLog('AuthException code: user_null');
        _debugLog('AuthException message: No user returned after login.');
        throw StateError('No pudimos iniciar sesion.');
      }
      _debugLog('AUTH LOGIN RESULT: OK');
      _debugLog('auth_user_id_present: ${user.id.trim().isNotEmpty}');
      _debugLog('auth_user_email_present: ${user.email?.trim().isNotEmpty}');
      return _mapUser(user);
    } on supabase.AuthException catch (error) {
      _debugLog('AUTH LOGIN RESULT: ERROR');
      _logAuthException(error);
      rethrow;
    }
  }

  @override
  Future<void> signOut() {
    return client.auth.signOut();
  }

  @override
  Future<void> resetPasswordForEmail({
    required String email,
    required Uri redirectTo,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      _debugLog('PASSWORD_RESET_REQUEST:');
      _debugLog('email_present: ${normalizedEmail.isNotEmpty}');
      _debugLog('redirectTo: $redirectTo');
      await client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: redirectTo.toString(),
      );
      _debugLog('PASSWORD_RESET_REQUEST: OK');
    } on supabase.AuthException catch (error) {
      _debugLog('PASSWORD_RESET_REQUEST: ERROR');
      _logAuthException(error);
      rethrow;
    } catch (error) {
      _debugLog('PASSWORD_RESET_REQUEST: ERROR');
      _debugLog('error: ${error.runtimeType}');
      _debugLog(
        'classification: '
        '${classifyAuthFailure(message: error.toString(), error: error).name}',
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({required String password}) async {
    try {
      _debugLog(
        'PASSWORD_RECOVERY_SESSION: '
        '${client.auth.currentSession == null ? 'ERROR' : 'OK'}',
      );
      await client.auth.updateUser(
        supabase.UserAttributes(password: password),
      );
      _debugLog('PASSWORD_UPDATE: OK');
    } on supabase.AuthException catch (error) {
      _debugLog('PASSWORD_UPDATE: ERROR');
      _logAuthException(error);
      rethrow;
    } catch (error) {
      _debugLog('PASSWORD_UPDATE: ERROR');
      _debugLog('error: ${error.runtimeType}');
      rethrow;
    }
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

void _debugLog(String message) {
  // Diagnostics are intentionally sanitized: no passwords, tokens, sessions or
  // complete keys are logged.
  logAuthDiagnostic(message);
}

void _logAuthException(supabase.AuthException error) {
  _debugLog('AuthException statusCode: ${error.statusCode}');
  _debugLog('AuthException code: ${error.code}');
  _debugLog('AuthException message: ${error.message}');
  _debugLog(
    'classification: '
    '${classifyAuthFailure(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      error: error,
    ).name}',
  );
}
