import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release script and Flutter config use the same Supabase dart-defines',
      () {
    final root = _repoRoot();
    final script = File('${root.path}/scripts/android_build_release.ps1')
        .readAsStringSync();
    final config =
        File('${root.path}/packages/data/lib/src/supabase_config.dart')
            .readAsStringSync();

    for (final name in ['SUPABASE_URL', 'SUPABASE_ANON_KEY']) {
      expect(script, contains('--dart-define=$name='));
      expect(config, contains("String.fromEnvironment('$name')"));
    }
  });

  test('release script validates real Habitar Supabase project before build',
      () {
    final script = File(
      '${_repoRoot().path}/scripts/android_build_release.ps1',
    ).readAsStringSync();

    expect(script, contains('frmgwpbstezqjwbcshbw'));
    expect(script, contains('/auth/v1/settings'));
    expect(script, contains('Supabase release config:'));
    expect(script, contains('anon_key_masked'));
  });
}

Directory _repoRoot() {
  var current = Directory.current;
  while (!File('${current.path}/pubspec.yaml').existsSync() ||
      !Directory('${current.path}/supabase').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not find repository root.');
    }
    current = parent;
  }
  return current;
}
