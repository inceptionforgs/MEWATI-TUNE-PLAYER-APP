class SupabaseConfig {
  // No hardcoded fallback values. Both must be injected at build time via
  // --dart-define, e.g.:
  //   flutter build apk --release \
  //     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  //     --dart-define=SUPABASE_ANON_KEY=xxxx
  // flutter_dotenv/.env is intentionally NOT used here — .env is not listed
  // under pubspec.yaml's assets, so dotenv.load() was always a silent no-op
  // and any code relying on it here was actually falling through to the
  // hardcoded dev values. Never reintroduce a hardcoded fallback.
  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    if (_url.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not set. Pass it at build time with '
        '--dart-define=SUPABASE_URL=<your-url>.',
      );
    }
    return _url;
  }

  static String get anonKey {
    if (_anonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not set. Pass it at build time with '
        '--dart-define=SUPABASE_ANON_KEY=<your-anon-key>.',
      );
    }
    return _anonKey;
  }
}
