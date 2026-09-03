import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_themes.dart';
import '../../../providers/theme_provider.dart';
import 'color_wheel_picker.dart';

/// Custom Theme sub-section of Advance Settings (File 31b).
///
/// Dragging the wheel/shade slider updates the WHOLE app's theme live via
/// [ThemeProvider.previewCustomTheme] — nothing is persisted until "Set"
/// is pressed. If the user navigates away without pressing "Set", the
/// parent screen (advance_settings_screen.dart) calls
/// [ThemeProvider.cancelThemePreview] on pop, and this widget does the
/// same defensively in its own [dispose].
class CustomThemeSection extends StatefulWidget {
  const CustomThemeSection({super.key});

  @override
  State<CustomThemeSection> createState() => _CustomThemeSectionState();
}

class _CustomThemeSectionState extends State<CustomThemeSection> {
  late Color _pickedColor;
  late double _shade;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    _pickedColor = themeProvider.customColor;
    _shade = themeProvider.customShade;
  }

  @override
  void dispose() {
    // Safety net: if this widget is torn down some other way besides the
    // parent screen's own pop handler, still make sure no un-set preview
    // is left applied to the whole app.
    context.read<ThemeProvider>().cancelThemePreview();
    super.dispose();
  }

  void _updatePreview() {
    context.read<ThemeProvider>().previewCustomTheme(_pickedColor, _shade);
  }

  void _onColorChanged(Color color) {
    setState(() => _pickedColor = color);
    _updatePreview();
  }

  void _onShadeChanged(double shade) {
    setState(() => _shade = shade);
    _updatePreview();
  }

  Future<void> _onSet() async {
    await context.read<ThemeProvider>().commitCustomTheme(_pickedColor, _shade);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme saved')),
    );
  }

  Future<void> _onResetTheme() async {
    await context.read<ThemeProvider>().resetToDefaultTheme();
    if (!mounted) return;
    setState(() {
      _pickedColor = AppThemes.walkmanOrange.accent;
      _shade = 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watches ThemeProvider so this section's own text/buttons repaint in
    // the live-preview color too, same as the rest of the app.
    final t = context.watch<ThemeProvider>().theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Custom Theme',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag the wheel to preview live across the app. Nothing is saved until you press Set.',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 20),

        Center(
          child: ColorWheelPicker(
            color: _pickedColor,
            onChanged: _onColorChanged,
            size: 220,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Shade',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        ShadeSlider(
          baseColor: _pickedColor,
          shade: _shade,
          onChanged: _onShadeChanged,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _onResetTheme,
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.textPrimary,
                  side: BorderSide(color: t.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _onSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Set'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
