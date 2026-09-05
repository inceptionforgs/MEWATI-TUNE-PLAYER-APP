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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 25, offset: const Offset(0, -10)),
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
                    style: const TextStyle(
                      color: _scTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (queuePosition.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    queuePosition,
                    style: const TextStyle(color: _scTextSecondary, fontSize: 16),
                  ),
                ],
              ],
            ),
          ),
          if (singerName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                singerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _scTextSecondary, fontSize: 12),
              ),
            ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
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
          _SilverChromeSlider(onSeek: (d) => playerProvider.seek(d)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Drive Mode',
                button: true,
                child: _scMetalButton(
                  icon: Icons.drive_eta,
                  size: 38,
                  iconSize: 20,
                  onTap: () => Navigator.of(context).pushNamed(RouteNames.driveMode),
                ),
              ),
              Row(
                children: [
                  _scMetalButton(
                    icon: Icons.skip_previous,
                    size: 46,
                    onTap: () => playerProvider.previous(),
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
                                valueColor: AlwaysStoppedAnimation<Color>(_scButtonIcon),
                              ),
                            ),
                          ),
                        )
                      : _scMetalButton(
                          icon: isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 58,
                          iconSize: 26,
                          onTap: () => playerProvider.togglePlayPause(),
                        ),
                  const SizedBox(width: 16),
                  _scMetalButton(
                    icon: Icons.skip_next,
                    size: 46,
                    onTap: () => playerProvider.next(),
                  ),
                ],
              ),
              Semantics(
                label: loopMode == LoopMode.one ? 'Repeat one' : 'Repeat',
                button: true,
                child: _scMetalButton(
                  icon: loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                  size: 38,
                  iconSize: 20,
                  onTap: () {
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
                  active: loopMode != LoopMode.off,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scMetalButton({
    required IconData icon,
    required double size,
    double iconSize = 22,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [_scButtonIcon, Colors.black]
                : [_scMetalLight, _scMetalDark],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: active ? _scMetalLight : _scButtonIcon, size: iconSize),
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
                : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
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
                      onHorizontalDragUpdate: (d) => _updateDrag(d.localPosition.dx, width),
                      onHorizontalDragEnd: (_) => _commitDrag(duration),
                      onHorizontalDragCancel: _cancelDrag,
                      child: Container(
                        height: 18,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_fmt(position), style: const TextStyle(color: _scTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(_fmt(duration), style: const TextStyle(color: _scTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
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
