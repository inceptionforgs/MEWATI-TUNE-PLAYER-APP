import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_themes.dart';
import '../../../providers/theme_provider.dart';
import 'color_wheel_picker.dart';

class CustomThemeSection extends StatefulWidget {
  const CustomThemeSection({super.key});

  @override
  State<CustomThemeSection> createState() => _CustomThemeSectionState();
}

class _CustomThemeSectionState extends State<CustomThemeSection> {
  late Color _pickedColor;
  late double _shade;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = context.read<ThemeProvider>();
    _pickedColor = _themeProvider.customColor;
    _shade = _themeProvider.customShade;
  }

  @override
  void dispose() {
    _themeProvider.cancelThemePreview();
    super.dispose();
  }

  void _updatePreview() {
    _themeProvider.previewCustomTheme(_pickedColor, _shade);
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
    await _themeProvider.commitCustomTheme(_pickedColor, _shade);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme saved')),
    );
  }

  Future<void> _onResetTheme() async {
    await _themeProvider.resetToDefaultTheme();
    if (!mounted) return;
    setState(() {
      _pickedColor = AppThemes.walkmanOrange.accent;
      _shade = 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final Color onAccent = ThemeData.estimateBrightnessForColor(t.accent) == Brightness.light
        ? Colors.black
        : Colors.white;

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
                  foregroundColor: onAccent,
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
