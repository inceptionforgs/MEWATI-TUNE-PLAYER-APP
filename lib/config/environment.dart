import 'package:flutter/foundation.dart';

class Environment {
  static const String appName = 'Mewati Tune Player';
  static const String version = '1.0.0';

  static bool get isProduction => kReleaseMode;
  static bool get isDevelopment => kDebugMode;
}