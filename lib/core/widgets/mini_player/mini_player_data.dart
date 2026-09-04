// File: lib/core/widgets/mini_player/mini_player_data.dart
//
// Plain data holder for everything a themed mini player needs to render.
// mini_player_bar.dart builds one of these per frame (from PlayerProvider
// selects) and hands it to whichever theme widget is active, so every
// theme file has one single, stable constructor signature to depend on.
//
// `song` and `theme` are left as `dynamic` on purpose, matching the
// existing convention in this codebase (see the old mini_player_bar.dart),
// so this file doesn't need to import the concrete Song / AppThemeData
// types just to pass them through.

import 'package:just_audio/just_audio.dart';

import '../../../providers/player_provider.dart';

class MiniPlayerData {
  final dynamic song;
  final dynamic theme;
  final bool isPlaying;
  final bool isLoading;
  final String? errorMessage;
  final LoopMode loopMode;
  final String queuePosition;
  final PlayerProvider playerProvider;

  const MiniPlayerData({
    required this.song,
    required this.theme,
    required this.isPlaying,
    required this.isLoading,
    required this.errorMessage,
    required this.loopMode,
    required this.queuePosition,
    required this.playerProvider,
  });
}
