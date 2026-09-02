import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_themes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final authProvider = context.read<AuthProvider>();
    final t = themeProvider.theme;

    String displayName = 'Guest';
    bool isPremium = false;

    final profile = authProvider.profile;
    if (profile != null) {
      displayName = 'Mewati Listener';
      isPremium = profile.isPremium;
    }

    return Drawer(
      backgroundColor: t.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: t.surface,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                    style: TextStyle(
                      color: t.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isPremium ? 'VIP Member' : 'Free',
                      style: TextStyle(
                        color: isPremium ? t.accent : t.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 30, color: t.textPrimary.withOpacity(0.12)),
            Text(
              'THEME SELECT',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            ...AppThemes.all.map((themeData) {
              final isActive = themeProvider.themeId == themeData.id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () => themeProvider.setTheme(themeData.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? t.surface.withOpacity(0.08)
                          : t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? t.accent : t.textPrimary.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeData.accent,
                            border: Border.all(color: t.textPrimary.withOpacity(0.3)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            themeData.label,
                            style: TextStyle(
                              color: isActive ? t.accent : t.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.radio_button_checked,
                              color: t.accent, size: 14),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 18),
            Text(
              'EQUALIZER PRESETS',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            ...['normal', 'mewati-bass', 'beats', 'vocal', 'treble'].map((preset) {
              final label = preset == 'normal'
                  ? 'Normal'
                  : preset == 'mewati-bass'
                      ? 'Mewati Bass™'
                      : preset == 'beats'
                          ? 'Beats Mode'
                          : preset == 'vocal'
                              ? 'Vocal Boost'
                              : 'Treble Boost';
              final isActive = themeProvider.eqPreset == preset;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () => themeProvider.setEqPreset(preset),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? t.surface.withOpacity(0.08)
                          : t.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? t.accent : t.textPrimary.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isActive ? t.accent : t.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.radio_button_checked,
                              color: t.accent, size: 14),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 18),
            Text(
              'ABOUT APP',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.textPrimary.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mewati Tune Player',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version: 1.0.0 (Walkman Ed.)',
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Designed for premium audio experience with offline mode support.',
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 Mewati Beats Inc.',
                    style: TextStyle(
                      color: t.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}