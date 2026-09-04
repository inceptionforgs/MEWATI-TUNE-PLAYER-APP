import 'package:flutter/material.dart';

import 'app_theme_id.dart';

/// Immutable colour palette for a single app theme.
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
