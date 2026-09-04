import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// "Deep Black" theme.
///
/// Colour values are unchanged from the original app_themes.dart.
const AppThemeData cyberBlackTheme = AppThemeData(
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
