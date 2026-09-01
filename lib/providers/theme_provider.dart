import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_themes.dart';
import '../services/equalizer_service.dart';

class ThemeProvider extends ChangeNotifier {
  AppThemeId _themeId = AppThemes.defaultThemeId;
  String _eqPreset = 'mewati-bass';

  AppThemeId get themeId => _themeId;
  AppThemeData get theme => AppThemes.byId(_themeId);
  String get eqPreset => _eqPreset;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIdStr = prefs.getString('theme_id');
      if (themeIdStr != null) {
        final id = AppThemeId.values.firstWhere(
          (e) => e.toString() == themeIdStr,
          orElse: () => AppThemes.defaultThemeId,
        );
        _themeId = id;
      }

      final eq = prefs.getString('eq_preset');
      if (eq != null) {
        _eqPreset = eq;
      }

      notifyListeners();
    } catch (e) {
      // Ignore load errors; use defaults
    }
  }

  Future<void> setTheme(AppThemeId id) async {
    if (_themeId == id) return;
    _themeId = id;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_id', id.toString());
    } catch (e) {
      // Ignore save error
    }
  }

  Future<void> setEqPreset(String preset) async {
    if (_eqPreset == preset) return;
    _eqPreset = preset;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('eq_preset', preset);
    } catch (e) {
      // Ignore save error
    }

    await EqualizerService().applyPreset(preset);
  }
}