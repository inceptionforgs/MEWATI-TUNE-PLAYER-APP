import 'package:flutter/foundation.dart';

class Environment {
  static const String appName = 'Mewati Tune Player';
  static const String version = '1.0.0';

  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;

  // Same --dart-define pattern as SupabaseConfig: no hardcoded fallback.
  // Empty means "Sentry disabled" (a missing DSN is not an error — Sentry
  // reporting itself is optional, unlike Supabase credentials).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Keep this low in production — 1.0 traces every transaction and can
  // burn through a Sentry quota fast on even modest traffic.
  static const double sentryTracesSampleRate = 0.1;
}
