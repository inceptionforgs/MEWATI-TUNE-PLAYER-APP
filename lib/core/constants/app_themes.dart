import 'package:flutter/material.dart';

enum AppThemeId { walkmanOrange, cyberBlack, silverChrome }

class AppThemeData {
  final AppThemeId id;
  final String label;
  final Color accent;
  final Color accentLight;
  final Color accentDark;
  final List<Color> screenGradient;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const AppThemeData({
    required this.id,
    required this.label,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.screenGradient,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });
}

class AppThemes {
  static const AppThemeId defaultThemeId = AppThemeId.walkmanOrange;

  static const AppThemeData walkmanOrange = AppThemeData(
    id: AppThemeId.walkmanOrange,
    label: 'Walkman Orange',
    accent: Color(0xFFFF6600),
    accentLight: Color(0xFFFF944D),
    accentDark: Color(0xFFCC5200),
    screenGradient: [
      Color(0xFFFF802B),
      Color(0xFFFF6600),
      Color(0xFF2B1405),
    ],
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFFFFDF8),
    textSecondary: Color(0xB3FFFFFF),
  );

  static const AppThemeData cyberBlack = AppThemeData(
    id: AppThemeId.cyberBlack,
    label: 'Deep Black',
    accent: Color(0xFF00E5D6),
    accentLight: Color(0xFF6FFCF0),
    accentDark: Color(0xFF00A89C),
    screenGradient: [
      Color(0xFF1C1C1C),
      Color(0xFF101010),
      Color(0xFF000000),
    ],
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF888888),
  );

  static const AppThemeData silverChrome = AppThemeData(
    id: AppThemeId.silverChrome,
    label: 'Apple Green',
    accent: Color(0xFFC7CDD3),
    accentLight: Color(0xFFE7EAED),
    accentDark: Color(0xFF8A919A),
    screenGradient: [
      Color(0xFF6B7078),
      Color(0xFF3E4247),
      Color(0xFF16181A),
    ],
    background: Color(0xFF16181A),
    surface: Color(0xFF3E4247),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
  );

  static const List<AppThemeData> all = [
    walkmanOrange,
    cyberBlack,
    silverChrome,
  ];

  static AppThemeData byId(AppThemeId id) {
    switch (id) {
      case AppThemeId.walkmanOrange:
        return walkmanOrange;
      case AppThemeId.cyberBlack:
        return cyberBlack;
      case AppThemeId.silverChrome:
        return silverChrome;
    }
  }
}
