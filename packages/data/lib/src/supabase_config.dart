class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static SupabaseConfig fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be provided with --dart-define.');
    }
    return const SupabaseConfig(url: url, anonKey: anonKey);
  }
}
