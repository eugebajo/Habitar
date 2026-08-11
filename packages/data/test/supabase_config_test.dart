import 'package:habitar_data/data.dart';
import 'package:test/test.dart';

void main() {
  test('cleans quoted release values and derives project ref', () {
    final config = SupabaseConfig(
      url: "'https://frmgwpbstezqjwbcshbw.supabase.co'",
      anonKey: '"sb_publishable_1234567890abcdef"',
    );

    expect(config.url, 'https://frmgwpbstezqjwbcshbw.supabase.co');
    expect(config.anonKey, 'sb_publishable_1234567890abcdef');
    expect(config.projectRef, 'frmgwpbstezqjwbcshbw');
    expect(config.maskedAnonKey, 'sb_p...cdef');
  });

  test('rejects missing, placeholder or malformed values', () {
    expect(
      () => SupabaseConfig(url: '', anonKey: 'sb_publishable_1234'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => SupabaseConfig(
        url: 'https://frmgwpbstezqjwbcshbw.supabase.co',
        anonKey: 'process.env.SUPABASE_KEY',
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => SupabaseConfig(
        url: 'https://frmgwpbstezqjwbcshbw.supabase.co',
        anonKey: 'not-a-supabase-key',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
