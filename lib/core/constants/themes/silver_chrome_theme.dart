import 'package:flutter/material.dart';

import 'app_theme_data.dart';
import 'app_theme_id.dart';

/// "Apple Green" theme (internal id: silverChrome).
///
/// Colour values are unchanged from the original app_themes.dart.
const AppThemeData silverChromeTheme = AppThemeData(
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
