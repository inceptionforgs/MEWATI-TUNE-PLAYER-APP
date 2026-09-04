// File: lib/screens/player/widgets/player_controls.dart
//
// Dispatcher — picks the right per-theme player controls based on the
// active theme, so every screen that does
// `import 'widgets/player_controls.dart'` and uses `PlayerControls()`
// keeps working exactly as before, unchanged.
//
// Right now all three themes render the same buttons (see
// player_controls/ folder — pure file separation for now); this is
// where each theme's own button styling gets plugged in later without
// touching this dispatcher.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_themes.dart';
import '../../../providers/theme_provider.dart';
import 'player_controls/cyber_black_player_controls.dart';
import 'player_controls/silver_chrome_player_controls.dart';
import 'player_controls/walkman_orange_player_controls.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<ThemeProvider>().theme.id;

    switch (themeId) {
      case AppThemeId.cyberBlack:
        return const CyberBlackPlayerControls();
      case AppThemeId.silverChrome:
        return const SilverChromePlayerControls();
      case AppThemeId.walkmanOrange:
      case AppThemeId.custom:
        // Custom theme is colour-only today (see custom_theme_builder.dart)
        // so it keeps using the default structural controls, exactly like
        // before this split.
        return const WalkmanOrangePlayerControls();
    }
  }
}
