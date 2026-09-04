import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// Builds a live [AppThemeData] from a wheel-picked [color] and a
/// [shade] (0.0 = darkest, 1.0 = lightest), matching ShadeSlider's
/// HSV-value mapping in color_wheel_picker.dart.
///
/// Behaviour is unchanged from the original AppThemes.buildCustom():
/// background/surface/text colours stay fixed regardless of which
/// preset theme (walkmanOrange / cyberBlack / silverChrome) was active
/// before switching to Custom — only accent, accentLight, accentDark
/// and the gradient are derived from the picked colour.
AppThemeData buildCustomTheme(Color color, double shade) {
  final hsv = HSVColor.fromColor(color);
  final clampedShade = shade.clamp(0.0, 1.0);
  final value = 0.15 + (1.0 - 0.15) * clampedShade;

  final accent = hsv.withValue(value).toColor();
  final accentLight = hsv.withValue((value + 0.25).clamp(0.0, 1.0)).toColor();
  final accentDark = hsv.withValue((value - 0.25).clamp(0.0, 1.0)).toColor();

  return AppThemeData(
    id: AppThemeId.custom,
    label: 'Custom',
    accent: accent,
    accentLight: accentLight,
    accentDark: accentDark,
    screenGradient: [accentLight, accent, accentDark],
    background: const Color(0xFF121212),
    surface: const Color(0xFF1E1E1E),
    textPrimary: const Color(0xFFFFFDF8),
    textSecondary: const Color(0xB3FFFFFF),
  );
}
