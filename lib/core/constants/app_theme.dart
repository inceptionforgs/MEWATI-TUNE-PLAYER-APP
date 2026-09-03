import 'package:flutter/material.dart';
import 'app_themes.dart';

/// Converts an [AppThemeData] color palette into a Flutter [ThemeData]
/// for MaterialApp.theme.
class AppTheme {
  static ThemeData fromAppTheme(AppThemeData t) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: t.background,
      primaryColor: t.accent,
      colorScheme: ColorScheme.dark(
        primary: t.accent,
        secondary: t.accentLight,
        surface: t.surface,
        onPrimary: t.textPrimary,
        onSurface: t.textPrimary,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: t.textPrimary,
            displayColor: t.textPrimary,
          ),
    );
  }
}
