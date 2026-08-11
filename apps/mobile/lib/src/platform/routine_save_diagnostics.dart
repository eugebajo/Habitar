import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

const bool routineSaveDiagnosticsEnabled =
    bool.fromEnvironment('HABITAR_ROUTINE_DIAGNOSTICS');

String routineSaveDiagnosticCode(Object error) {
  if (error is supabase.PostgrestException) {
    final code = error.code;
    if (code != null && code.trim().isNotEmpty) {
      return 'HABITAR_ROUTINE_SAVE_${code.trim()}';
    }
    return 'HABITAR_ROUTINE_SAVE_POSTGREST';
  }
  if (error is supabase.AuthException) {
    final code = error.code;
    if (code != null && code.trim().isNotEmpty) {
      return 'HABITAR_ROUTINE_SAVE_AUTH_${code.trim()}';
    }
    final status = error.statusCode;
    if (status != null && status.trim().isNotEmpty) {
      return 'HABITAR_ROUTINE_SAVE_AUTH_$status';
    }
    return 'HABITAR_ROUTINE_SAVE_AUTH';
  }
  if (error is ArgumentError) {
    return 'HABITAR_ROUTINE_SAVE_VALIDATION';
  }
  if (error is StateError) {
    return 'HABITAR_ROUTINE_SAVE_STATE';
  }
  return 'HABITAR_ROUTINE_SAVE_UNKNOWN';
}

bool get shouldShowRoutineSaveDiagnosticCode =>
    kDebugMode || routineSaveDiagnosticsEnabled;

void logRoutineSaveFailure(Object error, StackTrace stackTrace) {
  if (!shouldShowRoutineSaveDiagnosticCode) return;
  final code = routineSaveDiagnosticCode(error);
  developer.log(
    'Routine save failed: $code',
    name: 'HabitarRoutineSave',
    error: error,
    stackTrace: stackTrace,
  );
  if (error is supabase.PostgrestException) {
    developer.log('PostgREST code: ${error.code}', name: 'HabitarRoutineSave');
    developer.log(
      'PostgREST message: ${error.message}',
      name: 'HabitarRoutineSave',
    );
    developer.log(
      'PostgREST details: ${error.details}',
      name: 'HabitarRoutineSave',
    );
    developer.log('PostgREST hint: ${error.hint}', name: 'HabitarRoutineSave');
  } else if (error is supabase.AuthException) {
    developer.log(
      'AuthException statusCode: ${error.statusCode}',
      name: 'HabitarRoutineSave',
    );
    developer.log(
      'AuthException code: ${error.code}',
      name: 'HabitarRoutineSave',
    );
    developer.log(
      'AuthException message: ${error.message}',
      name: 'HabitarRoutineSave',
    );
  }
}
