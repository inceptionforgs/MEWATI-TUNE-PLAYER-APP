// File: lib/screens/player/widgets/player_controls.dart
//
// Dispatcher — unchanged. Still picks the right per-theme player
// controls based on the active theme.

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
        return const WalkmanOrangePlayerControls();
    }
  }
}
