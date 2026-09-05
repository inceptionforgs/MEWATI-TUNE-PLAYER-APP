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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.nowPlaying),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverImageUrl != null
                        ? Image.network(
                            song.coverImageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: t.surface,
                            child: Icon(Icons.music_note, color: t.textPrimary),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (queuePosition.isNotEmpty)
                          Text(
                            queuePosition,
                            style: TextStyle(
                              color: t.textPrimary.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Drive Mode',
                    button: true,
                    child: IconButton(
                      icon: Icon(Icons.drive_eta, color: t.textPrimary),
                      onPressed: () => Navigator.of(context)
                          .pushNamed(RouteNames.driveMode),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    color: t.textPrimary,
                    onPressed: () => playerProvider.previous(),
                  ),
                  isLoading
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(t.accent),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          color: t.textPrimary,
                          iconSize: 32,
                          onPressed: () => playerProvider.togglePlayPause(),
                        ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    color: t.textPrimary,
                    onPressed: () => playerProvider.next(),
                  ),
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        errorMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.redAccent, fontSize: 11),
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
            const SizedBox(height: 8),
            _DefaultSlider(t: t, onSeek: (d) => playerProvider.seek(d)),
          ],
        ),
      ),
    );
  }
}

class _DefaultSlider extends StatefulWidget {
  final dynamic t;
  final void Function(Duration position) onSeek;

  const _DefaultSlider({required this.t, required this.onSeek});

  @override
  State<_DefaultSlider> createState() => _DefaultSliderState();
}

class _DefaultSliderState extends State<_DefaultSlider> {
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
    final t = widget.t;

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
                        height: 4,
                        decoration: BoxDecoration(
                          color: t.textPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: pct,
                          child: Container(
                            decoration: BoxDecoration(
                              color: t.accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(position),
                      style: TextStyle(
                        color: t.textPrimary.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      _fmt(duration),
                      style: TextStyle(
                        color: t.textPrimary.withOpacity(0.6),
                        fontSize: 11,
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
