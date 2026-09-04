// File: lib/core/widgets/mini_player/themes/mini_player_cyber_black.dart
//
// Cyber Black mini player: colors taken 1:1 from the HTML mockup.
// Hardcoded on purpose (per request) instead of reading from
// ThemeProvider, so this widget ignores the app's existing color tokens.
// Self-contained — touch only this file for further Cyber Black tweaks.

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../providers/player_provider.dart';
import '../../../../routes/route_names.dart';
import '../../../extensions/duration_extensions.dart';
import '../mini_player_data.dart';

const _cbBackground = Color(0xFF0B0B0B);
const _cbTextPrimary = Colors.white;
const _cbTextSecondary = Color(0xFF9A9A9A);
const _cbAccentBlue = Color(0xFF2199D6);
const _cbTrackBg = Color(0xFF2C2C2C);
const _cbTrackBorder = Color(0xFF555555);
const _cbProgressFill = Color(0xFF9A9A9A);
const _cbRepeatOneBadge = Color(0xFF4CAF50);

class MiniPlayerCyberBlack extends StatelessWidget {
  final MiniPlayerData data;

  const MiniPlayerCyberBlack({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final song = data.song;
    final isPlaying = data.isPlaying;
    final isLoading = data.isLoading;
    final errorMessage = data.errorMessage;
    final loopMode = data.loopMode;
    final queuePosition = data.queuePosition;
    final playerProvider = data.playerProvider;

    final singerName = (song.singerName as String?) ?? '';
    final subtitleParts = <String>[
      if (singerName.isNotEmpty) singerName,
      if (queuePosition.isNotEmpty) queuePosition,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        22,
        24,
        16 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      decoration: const BoxDecoration(
        color: _cbBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(RouteNames.nowPlaying),
            child: Column(
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _cbTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitleParts.join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _cbTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
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
          const SizedBox(height: 16),
          _CyberBlackSlider(onSeek: (d) => playerProvider.seek(d)),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Drive Mode',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.drive_eta, color: _cbTextPrimary),
                  tooltip: 'Drive Mode',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.driveMode),
                ),
              ),
              Row(
                children: [
                  _cbCircleButton(
                    icon: Icons.skip_previous,
                    size: 58,
                    onTap: () => playerProvider.previous(),
                  ),
                  const SizedBox(width: 18),
                  isLoading
                      ? const SizedBox(
                          width: 80,
                          height: 80,
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_cbAccentBlue),
                            ),
                          ),
                        )
                      : _cbCircleButton(
                          icon: isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 80,
                          iconSize: 34,
                          onTap: () => playerProvider.togglePlayPause(),
                        ),
                  const SizedBox(width: 18),
                  _cbCircleButton(
                    icon: Icons.skip_next,
                    size: 58,
                    onTap: () => playerProvider.next(),
                  ),
                ],
              ),
              Semantics(
                label: loopMode == LoopMode.one ? 'Repeat one' : 'Repeat',
                button: true,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(
                        loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                        color: _cbTextPrimary,
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
                    if (loopMode == LoopMode.one)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: _cbRepeatOneBadge,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: _cbBackground,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cbCircleButton({
    required IconData icon,
    required double size,
    double iconSize = 26,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _cbAccentBlue, width: 2),
        ),
        child: Icon(icon, color: _cbAccentBlue, size: iconSize),
      ),
    );
  }
}

class _CyberBlackSlider extends StatefulWidget {
  final void Function(Duration position) onSeek;

  const _CyberBlackSlider({required this.onSeek});

  @override
  State<_CyberBlackSlider> createState() => _CyberBlackSliderState();
}

class _CyberBlackSliderState extends State<_CyberBlackSlider> {
  double? _dragValue;

  String _fmt(Duration d) => d.asCompact;

  void _updateDrag(double localDx, double width) {
    if (width <= 0) return;
    final pct = (localDx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = pct);
  }

  void _commitDrag(Duration duration) {
    if (_dragValue == null) return;
    widget.onSeek(Duration(
      milliseconds: (_dragValue! * duration.inMilliseconds).round(),
    ));
    setState(() => _dragValue = null);
  }

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      onTapDown: (d) => _updateDrag(d.localPosition.dx, width),
                      onTapUp: (_) => _commitDrag(duration),
                      onHorizontalDragUpdate: (d) =>
                          _updateDrag(d.localPosition.dx, width),
                      onHorizontalDragEnd: (_) => _commitDrag(duration),
                      child: Container(
                        height: 12,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: _cbTrackBg,
                          border: Border.all(color: _cbTrackBorder, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(color: _cbProgressFill),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(position),
                      style: const TextStyle(color: _cbTextSecondary, fontSize: 12),
                    ),
                    Text(
                      _fmt(duration),
                      style: const TextStyle(color: _cbTextSecondary, fontSize: 12),
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
