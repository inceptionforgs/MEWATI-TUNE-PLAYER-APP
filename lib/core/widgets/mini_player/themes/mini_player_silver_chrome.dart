import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../providers/player_provider.dart';
import '../../../../routes/route_names.dart';
import '../../../extensions/duration_extensions.dart';
import '../mini_player_data.dart';

const _scTextPrimary = Colors.white;
const _scTextSecondary = Color(0xFFCCCCCC);
const _scMetalLight = Color(0xFFE0E0E0);
const _scMetalDark = Color(0xFFB0B0B0);
const _scButtonIcon = Color(0xFF333333);
const _scTrackFill = Color(0xFFA0A0A0);

class MiniPlayerSilverChrome extends StatelessWidget {
  final MiniPlayerData data;

  const MiniPlayerSilverChrome({Key? key, required this.data}) : super(key: key);

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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        8 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3A3A), Color(0xFF1A1A1A)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        border: const Border(
          top: BorderSide(color: _scMetalLight, width: 2),
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
                    color: _scTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (singerName.isNotEmpty || queuePosition.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [singerName, queuePosition]
                        .where((s) => s.isNotEmpty)
                        .join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _scTextSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      playerProvider.clearError();
                      playerProvider.togglePlayPause();
                    },
                    child: const Text('Retry', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _SilverChromeSlider(onSeek: (d) => playerProvider.seek(d)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Drive Mode',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.drive_eta, color: _scTextPrimary),
                  tooltip: 'Drive Mode',
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.driveMode),
                ),
              ),
              Row(
                children: [
                  _scCircleButton(
                    icon: Icons.skip_previous,
                    size: 54,
                    onTap: () => playerProvider.previous(),
                  ),
                  const SizedBox(width: 16),
                  isLoading
                      ? const SizedBox(
                          width: 74,
                          height: 74,
                          child: Padding(
                            padding: EdgeInsets.all(22),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_scButtonIcon),
                            ),
                          ),
                        )
                      : _scCircleButton(
                          icon: isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 74,
                          iconSize: 32,
                          onTap: () => playerProvider.togglePlayPause(),
                        ),
                  const SizedBox(width: 16),
                  _scCircleButton(
                    icon: Icons.skip_next,
                    size: 54,
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
                        color: _scTextPrimary,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scCircleButton({
    required IconData icon,
    required double size,
    double iconSize = 24,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_scMetalLight, _scMetalDark],
          ),
          border: active ? Border.all(color: _scButtonIcon, width: 1.5) : null,
        ),
        child: Icon(icon, color: _scButtonIcon, size: iconSize),
      ),
    );
  }
}

class _SilverChromeSlider extends StatefulWidget {
  final void Function(Duration position) onSeek;

  const _SilverChromeSlider({required this.onSeek});

  @override
  State<_SilverChromeSlider> createState() => _SilverChromeSliderState();
}

class _SilverChromeSliderState extends State<_SilverChromeSlider> {
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

  void _cancelDrag() {
    if (_dragValue == null) return;
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
                      onTapCancel: _cancelDrag,
                      onHorizontalDragUpdate: (d) =>
                          _updateDrag(d.localPosition.dx, width),
                      onHorizontalDragEnd: (_) => _commitDrag(duration),
                      onHorizontalDragCancel: _cancelDrag,
                      child: Container(
                        height: 10,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_scMetalDark, _scMetalLight, _scMetalDark],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(color: _scTrackFill),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position),
                        style: const TextStyle(
                            color: _scTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(_fmt(duration),
                        style: const TextStyle(
                            color: _scTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
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
