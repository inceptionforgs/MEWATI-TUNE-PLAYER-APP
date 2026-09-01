import 'package:flutter/material.dart';
import 'app_themes.dart';

class AppTheme {
  static ThemeData fromAppTheme(AppThemeData data) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: data.background,
      primaryColor: data.accent,
      colorScheme: ColorScheme.dark(
        primary: data.accent,
        secondary: data.accentLight,
        background: data.background,
        surface: data.surface,
      ),
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: data.textPrimary,
            displayColor: data.textPrimary,
          ),
      useMaterial3: true,
    );
  }
}