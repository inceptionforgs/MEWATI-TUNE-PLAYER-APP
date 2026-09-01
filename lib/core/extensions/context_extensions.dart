import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_themes.dart';
import '../../providers/theme_provider.dart';

extension ContextExtensions on BuildContext {
  AppThemeData get appTheme => watch<ThemeProvider>().theme;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.grey.shade900,
      ),
    );
  }

  void navigateTo(Widget screen) {
    Navigator.of(this).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void pop([Object? result]) {
    Navigator.of(this).pop(result);
  }
}