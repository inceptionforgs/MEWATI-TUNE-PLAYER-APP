import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../providers/player_provider.dart';
import '../../../../providers/theme_provider.dart';

/// Player controls (shuffle / prev / play-pause / next / repeat) used
/// for the Deep Black theme.
///
/// Content is currently identical to WalkmanOrangePlayerControls — this
/// is a pure file-separation step so Deep Black's buttons can get their
/// own look later without touching the other themes.
class CyberBlackPlayerControls extends StatelessWidget {
  const CyberBlackPlayerControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final isLoading = context.select<PlayerProvider, bool>((p) => p.isLoading);

    String _repeatLabel(LoopMode mode) {
      switch (mode) {
        case LoopMode.one:
          return 'Repeat one';
        case LoopMode.all:
          return 'Repeat all';
        case LoopMode.off:
          return 'Repeat off';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          label: 'Shuffle',
          child: IconButton(
            icon: Icon(
              Icons.shuffle,
              color: playerProvider.shuffleMode
                  ? t.accent
                  : t.textPrimary.withOpacity(0.85),
              size: 22,
            ),
            onPressed: () => playerProvider.toggleShuffle(),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Previous',
          child: IconButton(
            icon: Icon(Icons.skip_previous, color: t.textPrimary, size: 28),
            onPressed: () => playerProvider.previous(),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.textPrimary, width: 2),
            color: t.textPrimary.withOpacity(0.08),
          ),
          child: Semantics(
            button: true,
            label: playerProvider.isPlaying ? 'Pause' : 'Play',
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(t.textPrimary),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: t.textPrimary,
                      size: 28,
                    ),
                    onPressed: () => playerProvider.togglePlayPause(),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'Next',
          child: IconButton(
            icon: Icon(Icons.skip_next, color: t.textPrimary, size: 28),
            onPressed: () => playerProvider.next(),
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: _repeatLabel(playerProvider.loopMode),
          child: IconButton(
            icon: Icon(
              playerProvider.loopMode == LoopMode.one
                  ? Icons.repeat_one
                  : Icons.repeat,
              color: playerProvider.loopMode != LoopMode.off
                  ? t.accent
                  : t.textPrimary.withOpacity(0.85),
              size: 22,
            ),
            onPressed: () {
              final current = playerProvider.loopMode;
              LoopMode next;
              if (current == LoopMode.off) {
                next = LoopMode.all;
              } else if (current == LoopMode.all) {
                next = LoopMode.one;
              } else {
                next = LoopMode.off;
              }
              playerProvider.setLoopMode(next);
            },
          ),
        ),
      ],
    );
  }
}
