// File: lib/core/widgets/mini_player/themes/mini_player_default.dart
// Unchanged — already has Drive Mode (not Shuffle) and matches the
// prototype's default mini player.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../providers/player_provider.dart';
import '../../../../routes/route_names.dart';
import '../../../extensions/duration_extensions.dart';
import '../mini_player_data.dart';

class MiniPlayerDefault extends StatelessWidget {
  final MiniPlayerData data;

  const MiniPlayerDefault({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = data.theme;
    final song = data.song;
    final isPlaying = data.isPlaying;
    final isLoading = data.isLoading;
    final errorMessage = data.errorMessage;
    final loopMode = data.loopMode;
    final queuePosition = data.queuePosition;
    final playerProvider = data.playerProvider;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.surface, t.background],
        ),
