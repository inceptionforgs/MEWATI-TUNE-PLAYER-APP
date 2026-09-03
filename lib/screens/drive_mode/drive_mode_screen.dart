// File: lib/screens/drive_mode/drive_mode_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

/// Drive Mode (File 32 — F2). Replaces the normal player UI with a
/// minimal, high-contrast, large-touch-target screen meant to be safe to
/// glance at / tap while driving:
///   - Only 3 XXL/XXXL buttons: Previous, Play/Pause, Next
///   - A thick seek bar
///   - A simplified song list with much larger rows (~4 visible instead
///     of the normal list's ~10)
///   - No other icons/actions (menu, repeat, favorite, download, etc.)
///   - Exiting always asks for confirmation
///   - Screen stays awake the whole time this screen is active
///
/// Entered by tapping the Drive Mode icon that replaces the Shuffle icon
/// wherever it used to appear (see File 33's fix to mini_player_bar.dart).
class DriveModeScreen extends StatefulWidget {
  const DriveModeScreen({super.key});

  @override
  State<DriveModeScreen> createState() => _DriveModeScreenState();
}

class _DriveModeScreenState extends State<DriveModeScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final t = context.read<ThemeProvider>().theme;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Exit Drive Mode?', style: TextStyle(color: t.textPrimary)),
        content: Text(
          'You will return to the normal player screen.',
          style: TextStyle(color: t.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: t.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Exit', style: TextStyle(color: t.accent)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    // Fixed (Item 9): read the provider for method calls only — do NOT
    // context.watch the whole provider here, since PlayerProvider calls
    // notifyListeners() on every ~200ms position tick, which was causing
    // this entire screen to rebuild that often. Fields that change
    // infrequently (song, queue, isPlaying) use context.select so this
    // widget only rebuilds when that specific field changes; position and
    // duration are read via their ValueNotifiers further down so only the
    // seek-bar section rebuilds on every tick.
    final playerProvider = context.read<PlayerProvider>();
    final song = context.select<PlayerProvider, Song?>((p) => p.currentSong);
    final queue = context.select<PlayerProvider, List<Song>>((p) => p.queue);
    final isPlaying = context.select<PlayerProvider, bool>((p) => p.isPlaying);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: just the Exit button — nothing else, to keep
              // accidental-touch surface area minimal while driving.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldExit = await _confirmExit(context);
                      if (shouldExit && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    label: const Text(
                      'Exit Drive Mode',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // High-contrast, large song title/artist — no other icons.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      song?.title ?? 'Nothing playing',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song?.singerName ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.accent,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Thick seek bar. Wrapped in ValueListenableBuilders on
              // positionNotifier/durationNotifier (Item 9) so only this
              // section rebuilds on every position tick, not the whole
              // screen.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ValueListenableBuilder<Duration>(
                  valueListenable: playerProvider.durationNotifier,
                  builder: (context, duration, _) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: playerProvider.positionNotifier,
                      builder: (context, position, __) {
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 14,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                                activeTrackColor: t.accent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: duration.inMilliseconds > 0
                                    ? position.inMilliseconds
                                        .clamp(0, duration.inMilliseconds)
                                        .toDouble()
                                    : 0.0,
                                max: duration.inMilliseconds > 0
                                    ? duration.inMilliseconds.toDouble()
                                    : 1.0,
                                onChanged: (value) {
                                  playerProvider.seek(Duration(milliseconds: value.round()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position),
                                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                  Text(_formatDuration(duration),
                                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Only 3 buttons — XXL/XXXL, nothing else (no repeat,
              // shuffle, favorite, download, or menu).
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DriveModeButton(
                    icon: Icons.skip_previous,
                    size: 64,
                    onTap: playerProvider.previous,
                  ),
                  _DriveModeButton(
                    icon: isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    size: 108,
                    color: t.accent,
                    onTap: playerProvider.togglePlayPause,
                  ),
                  _DriveModeButton(
                    icon: Icons.skip_next,
                    size: 64,
                    onTap: playerProvider.next,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),

              // Simplified song list — much larger rows (~4 visible vs
              // the normal list's ~10), tap-to-play only, no other
              // actions per row.
              Expanded(
                child: queue.isEmpty
                    ? const Center(
                        child: Text('Queue is empty', style: TextStyle(color: Colors.white54, fontSize: 18)),
                      )
                    : ListView.builder(
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final rowSong = queue[index];
                          final isCurrent = song != null && rowSong.id == song.id;
                          return _DriveModeSongRow(
                            song: rowSong,
                            isCurrent: isCurrent,
                            accent: t.accent,
                            onTap: () {
                              playerProvider.setPlaylist(songs: queue, startIndex: index);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriveModeButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _DriveModeButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Drive mode control',
      child: InkWell(
        borderRadius: BorderRadius.circular(size),
        onTap: onTap,
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}

/// Much larger row than the normal SongRow — roughly 4 rows fill the
/// visible list area instead of ~10, per File 32's spec, and only shows
/// title/artist + a play indicator. No like/download/menu icons.
class _DriveModeSongRow extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final Color accent;
  final VoidCallback onTap;

  const _DriveModeSongRow({
    required this.song,
    required this.isCurrent,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isCurrent ? accent.withOpacity(0.18) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: Colors.white12)),
        ),
        child: Row(
          children: [
            Icon(
              isCurrent ? Icons.graphic_eq : Icons.music_note,
              color: isCurrent ? accent : Colors.white38,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? accent : Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.singerName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
