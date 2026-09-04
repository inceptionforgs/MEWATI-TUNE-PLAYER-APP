// File: lib/screens/player/widgets/seek_bar.dart
//
// Dispatcher — picks the right per-theme seek bar based on the active
// theme, so every screen that does `import 'widgets/seek_bar.dart'` and
// uses `SeekBar()` keeps working exactly as before, unchanged.
//
// Right now all three themes render the same look (see seek_bar/ folder —
// pure file separation for now); this is where each theme's own seek-bar
// styling gets plugged in later without touching this dispatcher.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_themes.dart';
import '../../../providers/theme_provider.dart';
import 'seek_bar/cyber_black_seek_bar.dart';
import 'seek_bar/silver_chrome_seek_bar.dart';
import 'seek_bar/walkman_orange_seek_bar.dart';

class SeekBar extends StatelessWidget {
  const SeekBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeId = context.watch<ThemeProvider>().theme.id;

    switch (themeId) {
      case AppThemeId.cyberBlack:
        return const CyberBlackSeekBar();
      case AppThemeId.silverChrome:
        return const SilverChromeSeekBar();
      case AppThemeId.walkmanOrange:
      case AppThemeId.custom:
        // Custom theme is colour-only today (see custom_theme_builder.dart)
        // so it keeps using the default structural seek bar, exactly like
        // before this split.
        return const WalkmanOrangeSeekBar();
    }
  }
}
