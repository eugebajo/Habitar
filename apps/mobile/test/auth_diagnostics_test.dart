import 'package:flutter_test/flutter_test.dart';
import 'package:habitar_mobile/src/platform/auth_diagnostics.dart';

void main() {
  test('classifies invalid credentials', () {
    expect(
      classifyAuthFailure(message: 'Invalid login credentials'),
      AuthDiagnosticKind.invalidCredentials,
    );
  });

  test('classifies email confirmation and redirect failures', () {
    expect(
      classifyAuthFailure(message: 'Email not confirmed'),
      AuthDiagnosticKind.emailNotConfirmed,
    );
    expect(
      classifyAuthFailure(message: 'Redirect URL is not allowed'),
      AuthDiagnosticKind.redirectUrlNotAllowed,
    );
  });

  test('classifies invalid config and network failures', () {
    expect(
      classifyAuthFailure(statusCode: '401', message: 'Invalid API key'),
      AuthDiagnosticKind.invalidSupabaseConfig,
    );
    expect(
      classifyAuthFailure(message: 'SocketException: Failed host lookup'),
      AuthDiagnosticKind.network,
    );
  });
}
