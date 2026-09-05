// File: lib/screens/player/widgets/seek_bar.dart
//
// Dispatcher — unchanged.

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
        return const WalkmanOrangeSeekBar();
    }
  }
}
