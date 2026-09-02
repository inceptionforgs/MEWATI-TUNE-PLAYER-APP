import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Hardcoded fallback values for development/testing.
  static const String _devUrl = 'https://vryngmkjnposksoaknik.supabase.co';
  static const String _devAnonKey = 'sb_publishable_Okwcoet2gdq9H0CY8y6oUA_g3-w-AKX';

  static String get url {
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