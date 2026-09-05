// File: lib/core/widgets/app_drawer.dart
//
// Restyled to match the "Mewati Song Player" Walkman-Edition prototype:
// pill-shaped rows, left colour swatch on theme rows, a glowing dot
// indicator on the active row (instead of a radio icon), and per-theme
// corner radius (Walkman Orange: 14, Deep Black/cyber: 4, Apple
// Green/silver-chrome: 10) — matching the prototype's --card-radius
// token for each theme. All providers, routes, and preset/theme ids are
// unchanged from before; only presentation changed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_themes.dart';
import '../constants/app_strings.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  /// Card/row corner radius per theme — mirrors the prototype's
  /// --card-radius (14 default / 4 cyber-black / 10 silver-chrome).
  static double _cardRadius(AppThemeId id) {
    switch (id) {
      case AppThemeId.cyberBlack:
        return 4;
      case AppThemeId.silverChrome:
        return 10;
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    // CHANGED: was context.read<ThemeProvider>() — that meant this
    // widget never rebuilt when theme/eq preset changed elsewhere, so
    // the selected radio circle here stayed stale until some other
    // rebuild happened to touch this drawer.
    // Fix: watch, not read — drawer was stuck on "Guest" after login
    // because it never rebuilt when auth state changed.
    final authProvider = context.watch<AuthProvider>();
    final t = themeProvider.theme;
    final radius = _cardRadius(t.id);

    final bool isLoggedIn = authProvider.isLoggedIn;
    final profile = authProvider.profile;

    // No hardcoded fake identity. There's no display-name field on
    // Profile (auth is anonymous-only), so we show a consistent,
    // honest label instead of pretending it's personalized.
    final String displayName = isLoggedIn ? 'Mewati Listener' : 'Guest';
    final String avatarLetter = displayName[0].toUpperCase();

    // Only show VIP if subscription_status genuinely says so
    // (client can't fake this thanks to the profiles trigger in File 17).
    final bool isPremium = profile?.isPremium ?? false;

    // Fixed 280px width to match the prototype's .drawer{width:280px}
    // instead of Flutter's default Material drawer width.
    return Drawer(
      width: 280,
      backgroundColor: t.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.surface,
                    border: Border.all(
                      color: t.textPrimary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatarLetter,
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
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Divider(height: 30, color: t.textPrimary.withOpacity(0.15)),

            _SectionTitle(label: 'THEME SELECT', color: t.textSecondary),
            const SizedBox(height: 10),
            ...AppThemes.all.map((themeData) {
              final isActive = themeProvider.themeId == themeData.id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _DrawerPillRow(
                  radius: radius,
                  isActive: isActive,
                  t: t,
                  onTap: () => themeProvider.setTheme(themeData.id),
                  leading: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeData.accent,
                      border: Border.all(color: t.textPrimary.withOpacity(0.3)),
                    ),
                  ),
                  label: themeData.label,
                ),
              );
            }).toList(),

            const SizedBox(height: 18),
            _SectionTitle(label: 'EQUALIZER PRESETS', color: t.textSecondary),
            const SizedBox(height: 10),
            ..._eqPresets.map((preset) {
              final isActive = themeProvider.eqPreset == preset.id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _DrawerPillRow(
                  radius: radius,
                  isActive: isActive,
                  t: t,
                  onTap: () => themeProvider.setEqPreset(preset.id),
                  label: preset.label,
                ),
              );
            }).toList(),

            const SizedBox(height: 18),
            _DrawerActionRow(
              icon: Icons.tune,
              label: AppStrings.advanceSettingsDrawerLabel,
              t: t,
              radius: radius,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(RouteNames.advanceSettings);
              },
            ),
            const SizedBox(height: 8),
            _DrawerActionRow(
              icon: Icons.feedback_outlined,
              label: AppStrings.feedbackDrawerLabel,
              t: t,
              radius: radius,
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed(RouteNames.feedback);
              },
            ),

            const SizedBox(height: 18),
            _SectionTitle(label: 'ABOUT APP', color: t.textSecondary),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: t.textPrimary.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.appName,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.appVersion,
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

class _EqPresetDef {
  final String id;
  final String label;
  const _EqPresetDef(this.id, this.label);
}

// Labels matched verbatim to the prototype's drawer EQ chips. The
// underlying ids are unchanged so ThemeProvider.setEqPreset(...) and
// EqualizerService keep working exactly as before.
const List<_EqPresetDef> _eqPresets = [
  _EqPresetDef('normal', 'Normal'),
  _EqPresetDef('mewati-bass', 'Mewati Bass™'),
  _EqPresetDef('beats', 'Beats Mode'),
  _EqPresetDef('vocal', 'Vocal Boost'),
  _EqPresetDef('treble', 'Treble Boost'),
];

class _SectionTitle extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionTitle({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}

/// A full-width pill row used for both the theme list and the EQ
/// preset list — matches the prototype's .theme-btn / .eq-preset-chip:
/// left label (with optional leading swatch), and a small dot on the
/// right that glows when active.
class _DrawerPillRow extends StatelessWidget {
  final double radius;
  final bool isActive;
  final dynamic t;
  final VoidCallback onTap;
  final String label;
  final Widget? leading;

  const _DrawerPillRow({
    required this.radius,
    required this.isActive,
    required this.t,
    required this.onTap,
    required this.label,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.08) : t.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isActive ? t.accent : t.textPrimary.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? t.accent : t.textPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? t.accent : Colors.white.withOpacity(0.5),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: t.accent.withOpacity(0.7),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action row (Advance Settings / Feedback) — matches the prototype's
/// .action-row: icon + label + chevron, same pill shape as the rows
/// above.
class _DrawerActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic t;
  final double radius;
  final VoidCallback onTap;

  const _DrawerActionRow({
    required this.icon,
    required this.label,
    required this.t,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: t.textPrimary.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: t.textPrimary.withOpacity(0.8), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: t.textPrimary.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: t.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
