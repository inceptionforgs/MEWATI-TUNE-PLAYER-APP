// File: lib/core/widgets/mini_player/mini_player_data.dart
// Unchanged.

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
