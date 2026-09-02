import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    // Select only infrequently changing values to avoid rebuilds on every position tick.
    final song = context.select<PlayerProvider, dynamic>((p) => p.currentSong);
    final hasSong = song != null;
    final isPlaying = context.select<PlayerProvider, bool>((p) => p.isPlaying);
    final shuffleMode = context.select<PlayerProvider, bool>((p) => p.shuffleMode);
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

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.surface, t.background],
        ),
        border: Border(
          top: BorderSide(color: t.textPrimary.withOpacity(0.10)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row (tap to open now playing)
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/now-playing'),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (queuePosition.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    queuePosition,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Time display is part of slider section to avoid duplicate
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Slider and time section (not tappable to navigate)
          _MiniPlayerSlider(
            onSeek: (duration) => playerProvider.seek(duration),
            textColor: t.textPrimary,
            secondaryTextColor: t.textSecondary,
            activeTrackColor: t.textPrimary,
            inactiveTrackColor: t.textPrimary.withOpacity(0.25),
            thumbColor: t.textPrimary,
          ),
          const SizedBox(height: 4),
          // Controls row (tap on empty area? We'll make only buttons tappable)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shuffle,
                  color: shuffleMode ? t.accent : t.textPrimary.withOpacity(0.85),
                ),
                onPressed: () => playerProvider.toggleShuffle(),
              ),
              Row(
                children: [
                  _circleButton(
                    icon: Icons.skip_previous,
                    size: 46,
                    onTap: () => playerProvider.previous(),
                    borderColor: t.textPrimary,
                    iconColor: t.textPrimary,
                  ),
                  const SizedBox(width: 16),
                  _circleButton(
                    icon: isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 58,
                    iconSize: 26,
                    onTap: () => playerProvider.togglePlayPause(),
                    borderColor: t.textPrimary,
                    iconColor: t.textPrimary,
                  ),
                  const SizedBox(width: 16),
                  _circleButton(
                    icon: Icons.skip_next,
                    size: 46,
                    onTap: () => playerProvider.next(),
                    borderColor: t.textPrimary,
                    iconColor: t.textPrimary,
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                  color: loopMode != LoopMode.off
                      ? t.accent
                      : t.textPrimary.withOpacity(0.85),
                ),
                onPressed: () {
                  final current = loopMode;
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required double size,
    double iconSize = 20,
    required VoidCallback onTap,
    required Color borderColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class _MiniPlayerSlider extends StatefulWidget {
  final void Function(Duration position) onSeek;
  final Color textColor;
  final Color secondaryTextColor;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final Color thumbColor;

  const _MiniPlayerSlider({
    Key? key,
    required this.onSeek,
    required this.textColor,
    required this.secondaryTextColor,
    required this.activeTrackColor,
    required this.inactiveTrackColor,
    required this.thumbColor,
  }) : super(key: key);

  @override
  State<_MiniPlayerSlider> createState() => _MiniPlayerSliderState();
}

class _MiniPlayerSliderState extends State<_MiniPlayerSlider> {
  double? _dragValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Use context.select to only rebuild on position/duration changes
    final duration = context.select<PlayerProvider, Duration>(
      (p) => p.duration ?? Duration.zero,
    );
    final position = context.select<PlayerProvider, Duration>(
      (p) => p.position,
    );

    final actualPct = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final pct = _dragValue ?? actualPct;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: widget.activeTrackColor,
            inactiveTrackColor: widget.inactiveTrackColor,
            thumbColor: widget.thumbColor,
          ),
          child: Slider(
            value: pct,
            onChanged: (v) {
              setState(() => _dragValue = v);
            },
            onChangeEnd: (v) {
              final newPos = Duration(
                milliseconds: (v * duration.inMilliseconds).round(),
              );
              widget.onSeek(newPos);
              setState(() => _dragValue = null);
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(position),
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: 13,
              ),
            ),
            Text(
              _fmt(duration),
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}