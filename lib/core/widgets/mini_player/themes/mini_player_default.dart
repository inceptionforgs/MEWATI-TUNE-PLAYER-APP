// File: lib/core/widgets/mini_player/themes/mini_player_default.dart
// Unchanged — already has Drive Mode (not Shuffle) and matches the
// prototype's default mini player.

import 'package:flutter/material.dart';
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
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(RouteNames.nowPlaying),
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
              ],
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      playerProvider.clearError();
                      playerProvider.togglePlayPause();
                    },
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          _MiniPlayerSlider(
            onSeek: (duration) => playerProvider.seek(duration),
            textColor: t.textPrimary,
            secondaryTextColor: t.textSecondary,
            activeTrackColor: t.textPrimary,
            inactiveTrackColor: t.textPrimary.withOpacity(0.25),
            thumbColor: t.textPrimary,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Drive Mode',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.drive_eta,
                    color: t.textPrimary.withOpacity(0.85),
                  ),
                  tooltip: 'Drive Mode',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.driveMode),
                ),
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
                  isLoading
                      ? Semantics(
                          label: 'Loading',
                          child: SizedBox(
                            width: 58,
                            height: 58,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(t.textPrimary),
                              ),
                            ),
                          ),
                        )
                      : _circleButton(
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

  String _fmt(Duration d) => d.asCompact;

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();

    return ValueListenableBuilder<Duration>(
      valueListenable: playerProvider.durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: playerProvider.positionNotifier,
          builder: (context, position, __) {
            final actualPct = duration.inMilliseconds == 0
                ? 0.0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);
            final pct = _dragValue ?? actualPct;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
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
          },
        );
      },
    );
  }
}
