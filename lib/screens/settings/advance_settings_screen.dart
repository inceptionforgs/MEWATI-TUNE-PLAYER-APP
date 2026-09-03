import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/custom_equalizer_section.dart';
import 'widgets/custom_theme_section.dart';

/// Advance Settings screen (File 31 — F2), opened from the drawer's
/// bottom row (File 19). Two sub-sections: Custom Equalizer and
/// Custom Theme.
///
/// Wrapped in PopScope so that leaving this screen WITHOUT pressing
/// "Set" on the Custom Theme tab reverts any live preview back to the
/// previously saved theme — CustomThemeSection's own dispose() already
/// calls ThemeProvider.cancelThemePreview() as the actual mechanism;
/// this PopScope callback is the explicit, readable guarantee of that
/// contract at the screen level.
class AdvanceSettingsScreen extends StatelessWidget {
  const AdvanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        // Defensive/explicit: revert any un-set theme preview. Safe to
        // call even if nothing is being previewed (it's a no-op then).
        context.read<ThemeProvider>().cancelThemePreview();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.surface,
            foregroundColor: t.textPrimary,
            title: const Text('Advance Settings'),
            bottom: TabBar(
              indicatorColor: t.accent,
              labelColor: t.textPrimary,
              unselectedLabelColor: t.textSecondary,
              tabs: const [
                Tab(text: 'Custom Equalizer'),
                Tab(text: 'Custom Theme'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: CustomEqualizerSection(),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: CustomThemeSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
