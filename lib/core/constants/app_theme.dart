import 'package:flutter/material.dart';

enum AppThemeId { walkmanOrange, cyberBlack, silverChrome, custom }

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
    label: 'Cyber Black',
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
    label: 'Silver Chrome',
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
      case AppThemeId.custom:
        // byId() has no color/shade to build from — callers that need the
        // actual custom theme must use ThemeProvider.theme (which calls
        // buildCustom with the user's saved color+shade) instead of this.
        // Falling back to the default preset here just avoids a crash for
        // any stray byId(custom) call.
        return walkmanOrange;
    }
  }

  /// Builds an AppThemeData on the fly from a user-picked [accent] color
  /// and a [shade] slider value (0.0 = darkest, 1.0 = lightest), for the
  /// Advance Settings > Custom Theme color-wheel picker (File 31).
  ///
  /// The app is a dark-themed player throughout, so `shade` only nudges
  /// the background/surface brightness within a narrow dark range — it
  /// does not attempt to produce a light theme (that would fight every
  /// existing screen's `t.textPrimary`/`t.textSecondary` choices).
  static AppThemeData buildCustom(Color accent, double shade) {
    final clampedShade = shade.clamp(0.0, 1.0);
    final hsv = HSVColor.fromColor(accent);

    final accentLight = hsv
        .withSaturation((hsv.saturation * 0.55).clamp(0.0, 1.0))
        .withValue((hsv.value + 0.28).clamp(0.0, 1.0))
        .toColor();
    final accentDark = hsv
        .withValue((hsv.value * 0.65).clamp(0.0, 1.0))
        .toColor();

    // Background/surface stay dark (album art, text, icons across the app
    // assume a dark backdrop) — shade only moves within a subtle range.
    final bgValue = 0.04 + (clampedShade * 0.09); // ~0.04–0.13
    final surfaceValue = (bgValue + 0.06).clamp(0.0, 1.0);
    final bgSaturation = (hsv.saturation * 0.12).clamp(0.0, 0.2);

    final background = HSVColor.fromAHSV(1.0, hsv.hue, bgSaturation, bgValue).toColor();
    final surface = HSVColor.fromAHSV(1.0, hsv.hue, bgSaturation, surfaceValue).toColor();

    return AppThemeData(
      id: AppThemeId.custom,
      label: 'Custom',
      accent: accent,
      accentLight: accentLight,
      accentDark: accentDark,
      screenGradient: [accentLight, accent, accentDark],
      background: background,
      surface: surface,
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xB3FFFFFF),
    );
  }
}
