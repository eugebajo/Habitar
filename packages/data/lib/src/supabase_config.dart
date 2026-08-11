class SupabaseConfig {
  SupabaseConfig({required String url, required String anonKey})
      : url = _cleanDefineValue(url),
        anonKey = _cleanDefineValue(anonKey) {
    _validateUrl(this.url);
    _validateAnonKey(this.anonKey);
  }

  final String url;
  final String anonKey;

  Uri get uri => Uri.parse(url);

  String get projectRef {
    final host = uri.host;
    const suffix = '.supabase.co';
    return host.endsWith(suffix)
        ? host.substring(0, host.length - suffix.length)
        : host;
  }

  String get maskedAnonKey {
    if (anonKey.length <= 8) return '****';
    return '${anonKey.substring(0, 4)}...'
        '${anonKey.substring(anonKey.length - 4)}';
  }

  static SupabaseConfig fromEnvironment() {
    final config = maybeFromEnvironment();
    if (config == null) {
      throw StateError(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be provided with --dart-define.');
    }
    return config;
  }

  static SupabaseConfig? maybeFromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) {
      return null;
    }
    return SupabaseConfig(url: url, anonKey: anonKey);
  }
}

String _cleanDefineValue(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2) {
    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
  }
  return trimmed;
}

void _validateUrl(String value) {
  if (value.isEmpty) {
    throw StateError('SUPABASE_URL is empty.');
  }
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw StateError('SUPABASE_URL is not a valid absolute URL.');
  }
  if (uri.scheme != 'https') {
    throw StateError('SUPABASE_URL must use https.');
  }
}

void _validateAnonKey(String value) {
  if (value.isEmpty) {
    throw StateError('SUPABASE_ANON_KEY is empty.');
  }
  if (value == 'change-me' || value.contains('process.env')) {
    throw StateError('SUPABASE_ANON_KEY contains a placeholder.');
  }
  final isPublishable = value.startsWith('sb_publishable_');
  final isLegacyJwt = value.startsWith('eyJ');
  if (!isPublishable && !isLegacyJwt) {
    throw StateError('SUPABASE_ANON_KEY has an unsupported format.');
  }
}
