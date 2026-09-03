// File: lib/core/widgets/mini_player_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../app.dart';
import '../extensions/duration_extensions.dart';

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
    // Fixed (Item 7): loading spinner tied to PlayerProvider.isLoading,
    // shown in place of the mini-player's play/pause icon while a playlist
    // is loading; and errorMessage surfaced as a small inline banner with
    // a retry action.
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
            // CHANGED: was Navigator.of(context) — this widget sits
            // outside the app's Navigator subtree (it's a sibling in
            // app.dart's Stack, not a descendant), so that call found
            // no Navigator and silently did nothing. Using the shared
            // key reaches the real Navigator directly.
            onTap: () => MewatiTunePlayerApp.navigatorKey.currentState
                ?.pushNamed(RouteNames.nowPlaying),
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
          // Fixed (Item 7): inline error banner with retry, shown when
          // PlayerProvider.errorMessage is set (e.g. playback failed).
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
              // [F2] Shuffle removed, replaced with Drive Mode in the same slot.
              Semantics(
                label: 'Drive Mode',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.drive_eta,
                    color: t.textPrimary.withOpacity(0.85),
                  ),
                  tooltip: 'Drive Mode',
                  // CHANGED: was Navigator.of(context) — same root
                  // cause as the header tap above, this is why the Drive
                  // Mode icon looked like it did nothing when tapped.
                  onPressed: () => MewatiTunePlayerApp.navigatorKey
                      .currentState?.pushNamed(RouteNames.driveMode),
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
                  // Fixed (Item 7): show a spinner instead of the
                  // play/pause icon while PlayerProvider.isLoading.
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

  // Fixed: was `inMinutes.remainder(60)`, which silently dropped the hour
  // count (e.g. 65 min -> showed "5:xx" / effectively "00:xx" once combined
  // with drag state). DurationExtensions.asCompact correctly shows
  // h:mm:ss once past 60 minutes, and m:ss below that.
  String _fmt(Duration d) => d.asCompact;

  @override
  Widget build(BuildContext context) {
    // Position/duration now come from PlayerProvider's ValueNotifiers
    // (added in File 24's fix) instead of context.select, so only this
    // slider rebuilds on every position tick — not the whole mini-player.
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
              children: [
                SliderTheme(
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
