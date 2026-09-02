import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Static fallback for development. In production, these values are loaded
  // from environment variables (.env) to avoid hardcoding keys in source.
  static const String _devUrl = 'https://vryngmkjnposksoaknik.supabase.co';
  static const String _devAnonKey = 'sb_publishable_Okwcoet2gdq9H0CY8y6oUA_g3-w-AKX';

  static String get url {
    // Try to load from .env if available (production/release builds).
    if (dotenv.isInitialized) {
      final envUrl = dotenv.env['SUPABASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) {
        return envUrl;
      }
    }
    return _devUrl;
  }

  static String get anonKey {
    if (dotenv.isInitialized) {
      final envKey = dotenv.env['SUPABASE_ANON_KEY'];
      if (envKey != null && envKey.isNotEmpty) {
        return envKey;
      }
    }
    return _devAnonKey;
  }
}