import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// "Walkman Orange" — the app's default theme.
///
/// Colour values are unchanged from the original app_themes.dart.
const AppThemeData walkmanOrangeTheme = AppThemeData(
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
