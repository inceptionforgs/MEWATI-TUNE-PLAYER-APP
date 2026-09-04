// File: lib/core/widgets/mini_player/mini_player_bar.dart
//
// Dispatcher only. Reads PlayerProvider/ThemeProvider once, packs the
// result into a MiniPlayerData, and hands off to the widget for the
// active theme. Add a new theme by:
//   1. Creating lib/core/widgets/mini_player/themes/mini_player_<name>.dart
//      with a `class MiniPlayer<Name> extends StatelessWidget` that takes
//      `{required MiniPlayerData data}`.
//   2. Importing it below and adding one `case` to the switch.
// No existing theme file needs to change when you do this.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../../../providers/player_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../constants/themes/app_theme_id.dart';
import 'mini_player_data.dart';
import 'themes/mini_player_cyber_black.dart';
import 'themes/mini_player_default.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    // Select only infrequently changing values to avoid rebuilds on every
    // position tick (position/duration are read separately, inside each
    // theme's slider, via PlayerProvider's ValueNotifiers).
    final song = context.select<PlayerProvider, dynamic>((p) => p.currentSong);
    final hasSong = song != null;
    final isPlaying = context.select<PlayerProvider, bool>((p) => p.isPlaying);
    final isLoading = context.select<PlayerProvider, bool>((p) => p.isLoading);
    final errorMessage =
        context.select<PlayerProvider, String?>((p) => p.errorMessage);
    final loopMode = context.select<PlayerProvider, LoopMode>((p) => p.loopMode);
    final currentQueueIndex =
        context.select<PlayerProvider, int>((p) => p.currentQueueIndex);
    final totalQueueLength =
        context.select<PlayerProvider, int>((p) => p.totalQueueLength);

    if (!hasSong) {
      return const SizedBox.shrink();
    }

    final queuePosition =
        (totalQueueLength > 0) ? '${currentQueueIndex + 1}/$totalQueueLength' : '';

    final data = MiniPlayerData(
      song: song,
      theme: t,
      isPlaying: isPlaying,
      isLoading: isLoading,
      errorMessage: errorMessage,
      loopMode: loopMode,
      queuePosition: queuePosition,
      playerProvider: playerProvider,
    );

    switch (t.id as AppThemeId) {
      case AppThemeId.cyberBlack:
        return MiniPlayerCyberBlack(data: data);
      default:
        return MiniPlayerDefault(data: data);
    }
  }
}
