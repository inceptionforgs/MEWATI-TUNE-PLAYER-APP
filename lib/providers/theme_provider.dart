import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_themes.dart';
import '../services/equalizer_service.dart';

const _themeIdKey = 'theme_id';
const _eqPresetKey = 'eq_preset';
const _customColorKey = 'custom_theme_color';
const _customShadeKey = 'custom_theme_shade';

class ThemeProvider extends ChangeNotifier {
  AppThemeId _themeId = AppThemes.defaultThemeId;
  String _eqPreset = 'mewati-bass';

  // Persisted custom-theme color/shade — only meaningful when
  // _themeId == AppThemeId.custom, but kept around even when a preset
  // theme is active so the color wheel can reopen showing the last pick.
  Color _customColor = AppThemes.walkmanOrange.accent;
  double _customShade = 0.5;

  // Ephemeral, NOT persisted: set while the user is dragging the color
  // wheel / shade slider in Advance Settings so the whole app can preview
  // it live. Cleared by [cancelThemePreview] if they leave without
  // pressing "Set", or by [commitCustomTheme] once they do.
  AppThemeData? _previewOverride;

  AppThemeId get themeId => _themeId;
  Color get customColor => _customColor;
  double get customShade => _customShade;
  bool get isPreviewingTheme => _previewOverride != null;

  AppThemeData get theme {
    if (_previewOverride != null) return _previewOverride!;
    if (_themeId == AppThemeId.custom) {
      return AppThemes.buildCustom(_customColor, _customShade);
    }
    return AppThemes.byId(_themeId);
  }

  String get eqPreset => _eqPreset;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeIdStr = prefs.getString(_themeIdKey);
      if (themeIdStr != null) {
        final id = AppThemeId.values.firstWhere(
          (e) => e.toString() == themeIdStr,
          orElse: () => AppThemes.defaultThemeId,
        );
        _themeId = id;
      }

      final customColorValue = prefs.getInt(_customColorKey);
      if (customColorValue != null) {
        _customColor = Color(customColorValue);
      }
      final customShadeValue = prefs.getDouble(_customShadeKey);
      if (customShadeValue != null) {
        _customShade = customShadeValue;
      }

      final eq = prefs.getString(_eqPresetKey);
      if (eq != null) {
        _eqPreset = eq;
      }

      notifyListeners();

      // Re-apply whatever EQ preset (including 'custom') was saved, now
      // that playback/equalizer service is around to receive it.
      await EqualizerService().applyPreset(_eqPreset);
    } catch (e) {
      // Ignore load errors; use defaults
    }
  }

  Future<void> setTheme(AppThemeId id) async {
    if (id == AppThemeId.custom) {
      // Preset-only entry point — picking a custom color goes through
      // commitCustomTheme instead, since it needs a color+shade.
      return;
    }
    if (_themeId == id && _previewOverride == null) return;
    _themeId = id;
    _previewOverride = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeIdKey, id.toString());
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
      await prefs.setString(_eqPresetKey, preset);
    } catch (e) {
      // Ignore save error
    }

    await EqualizerService().applyPreset(preset);
  }

  // -----------------------------------------------------------------
  // Custom theme: live preview (Advance Settings > Custom Theme, File 31)
  // -----------------------------------------------------------------

  /// Called continuously while the user drags the color wheel / shade
  /// slider. Updates the WHOLE app's live theme via [theme], but does
  /// NOT persist anything — closing the screen without pressing "Set"
  /// must revert to whatever was saved before.
  void previewCustomTheme(Color color, double shade) {
    _previewOverride = AppThemes.buildCustom(color, shade);
    notifyListeners();
  }

  /// Called when the user leaves Advance Settings > Custom Theme without
  /// pressing "Set" — discards the live preview and falls back to the
  /// previously saved theme.
  void cancelThemePreview() {
    if (_previewOverride == null) return;
    _previewOverride = null;
    notifyListeners();
  }

  /// Called when the user presses "Set" — persists the color+shade
  /// permanently and switches the active theme to custom.
  Future<void> commitCustomTheme(Color color, double shade) async {
    _customColor = color;
    _customShade = shade;
    _themeId = AppThemeId.custom;
    _previewOverride = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeIdKey, AppThemeId.custom.toString());
      await prefs.setInt(_customColorKey, color.value);
      await prefs.setDouble(_customShadeKey, shade);
    } catch (e) {
      // Ignore save error
    }
  }

  /// "Reset" button on the Custom Theme screen — restores the default
  /// preset theme and clears the live preview.
  Future<void> resetToDefaultTheme() async {
    _previewOverride = null;
    await setTheme(AppThemes.defaultThemeId);
  }
}
