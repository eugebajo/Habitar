import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

const bool _releaseAuthDiagnostics =
    bool.fromEnvironment('HABITAR_AUTH_DIAGNOSTICS');

enum AuthDiagnosticKind {
  invalidCredentials,
  emailNotConfirmed,
  redirectUrlNotAllowed,
  invalidSupabaseConfig,
  network,
  timeout,
  rateLimited,
  unknown,
}

AuthDiagnosticKind classifyAuthFailure({
  String? statusCode,
  String? code,
  required String message,
  Object? error,
}) {
  final text = [
    statusCode,
    code,
    message,
    if (error != null) error.runtimeType.toString(),
  ].whereType<String>().join(' ').toLowerCase();

  if (text.contains('invalid login credentials') ||
      text.contains('invalid_credentials')) {
    return AuthDiagnosticKind.invalidCredentials;
  }
  if (text.contains('email not confirmed') ||
      text.contains('email_not_confirmed')) {
    return AuthDiagnosticKind.emailNotConfirmed;
  }
  if (text.contains('redirect') &&
      (text.contains('not allowed') || text.contains('invalid'))) {
    return AuthDiagnosticKind.redirectUrlNotAllowed;
  }
  if (text.contains('invalid api key') ||
      text.contains('api key') ||
      text.contains('jwt') ||
      text.contains('unauthorized')) {
    return AuthDiagnosticKind.invalidSupabaseConfig;
  }
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('dns') ||
      text.contains('tls') ||
      text.contains('handshake')) {
    return AuthDiagnosticKind.network;
  }
  if (text.contains('timeout')) {
    return AuthDiagnosticKind.timeout;
  }
  if (text.contains('rate') || text.contains('429')) {
    return AuthDiagnosticKind.rateLimited;
  }
  return AuthDiagnosticKind.unknown;
}

void logAuthDiagnostic(String message) {
  if (!kDebugMode && !_releaseAuthDiagnostics) return;
  developer.log(message, name: 'HabitarAuth');
}
