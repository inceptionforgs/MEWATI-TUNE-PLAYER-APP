// File: lib/screens/settings/advance_settings_screen.dart
//
// UPDATED: custom dark header (back-circle + title, matching the
// prototype's .as-appbar/.as-back) instead of the default Material
// AppBar, and a background color pulled straight from the prototype
// (#0B0B0B) instead of t.background, since the prototype keeps this
// screen visually independent of the active theme. PopScope /
// cancelThemePreview() logic and both tab bodies are unchanged.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/custom_equalizer_section.dart';
import 'widgets/custom_theme_section.dart';

const _asBackground = Color(0xFF0B0B0B);
const _asAppBarBg = Color(0xFF1A1A1A);
const _asAccent = Color(0xFF2199D6);

class AdvanceSettingsScreen extends StatelessWidget {
  const AdvanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watched so the tab bodies (which read live theme accent for their
    // own sliders/buttons) still rebuild correctly; the chrome here is
    // intentionally theme-independent, matching the prototype.
    context.watch<ThemeProvider>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        context.read<ThemeProvider>().cancelThemePreview();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: _asBackground,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: _asAppBarBg,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _asBackground,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Advance Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const TabBar(
                        indicatorColor: _asAccent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Color(0xFF9A9A9A),
                        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        tabs: [
                          Tab(text: 'Custom Equalizer'),
                          Tab(text: 'Custom Theme'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
