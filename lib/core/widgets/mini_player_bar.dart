import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

class MiniPlayerBar extends StatefulWidget {
  const MiniPlayerBar({Key? key}) : super(key: key);

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> {
  double? _dragValue;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    if (!playerProvider.hasSong) {
      return const SizedBox.shrink();
    }

    final song = playerProvider.currentSong!;
    final duration = playerProvider.duration ?? Duration.zero;
    final position = playerProvider.position;
    final actualPct = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final pct = _dragValue ?? actualPct;

    final currentIndex = playerProvider.currentQueueIndex;
    final totalSongs = playerProvider.totalQueueLength;
    final queuePosition = (totalSongs > 0) ? '${currentIndex + 1}/$totalSongs' : '';

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/now-playing'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF212121), Color(0xFF141414)],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.10)),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
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
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  _fmt(position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _fmt(duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.25),
                thumbColor: Colors.white,
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
                  playerProvider.seek(newPos);
                  setState(() => _dragValue = null);
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: playerProvider.shuffleMode
                        ? t.accent
                        : Colors.white.withOpacity(0.85),
                  ),
                  onPressed: () => playerProvider.toggleShuffle(),
                ),
                Row(
                  children: [
                    _circleButton(
                      icon: Icons.skip_previous,
                      size: 46,
                      onTap: () => playerProvider.previous(),
                    ),
                    const SizedBox(width: 16),
                    _circleButton(
                      icon: playerProvider.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 58,
                      iconSize: 26,
                      onTap: () => playerProvider.togglePlayPause(),
                    ),
                    const SizedBox(width: 16),
                    _circleButton(
                      icon: Icons.skip_next,
                      size: 46,
                      onTap: () => playerProvider.next(),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    playerProvider.loopMode == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.repeat,
                    color: playerProvider.loopMode != LoopMode.off
                        ? t.accent
                        : Colors.white.withOpacity(0.85),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required double size,
    double iconSize = 20,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}