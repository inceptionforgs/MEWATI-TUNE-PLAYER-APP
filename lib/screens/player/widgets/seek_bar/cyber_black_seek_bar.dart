// File: lib/screens/player/widgets/seek_bar/silver_chrome_seek_bar.dart
//
// UPDATED: thick white-bordered black track with a metallic-grey fill —
// matches the prototype's silver-chrome np-seek override
// (18px height, 2px white border, black background, no separate thumb).
//
// FIXED (Batch 3 audit): added onTapCancel/onHorizontalDragCancel — the
// gesture only reset _dragValue on a successful onTapUp/onHorizontalDragEnd,
// so a cancelled gesture (e.g. a scroll winning the gesture arena) left the
// fill visually stuck at the last dragged position.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../providers/player_provider.dart';
import '../../../../providers/theme_provider.dart';

class SilverChromeSeekBar extends StatefulWidget {
  const SilverChromeSeekBar({Key? key}) : super(key: key);

  @override
  State<SilverChromeSeekBar> createState() => _SilverChromeSeekBarState();
}

class _SilverChromeSeekBarState extends State<SilverChromeSeekBar> {
  double? _dragValue;

  void _updateDrag(double localDx, double width, Duration duration) {
    if (width <= 0) return;
    final pct = (localDx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = pct);
  }

  void _commitDrag(Duration duration) {
    if (_dragValue == null) return;
    context.read<PlayerProvider>().seek(
          Duration(milliseconds: (_dragValue! * duration.inMilliseconds).round()),
        );
    setState(() => _dragValue = null);
  }

  // FIXED: resets the stuck-fill state when a tap/drag is cancelled
  // instead of committed (e.g. interrupted by a scroll or a system
  // gesture), instead of leaving _dragValue set indefinitely.
  void _cancelDrag() {
    if (_dragValue == null) return;
    setState(() => _dragValue = null);
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.read<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    return ValueListenableBuilder<Duration?>(
      valueListenable: playerProvider.durationNotifier,
      builder: (context, durationValue, _) {
        final duration = durationValue ?? Duration.zero;
        return ValueListenableBuilder<Duration>(
          valueListenable: playerProvider.positionNotifier,
          builder: (context, position, __) {
            final actualPct = duration.inMilliseconds == 0
                ? 0.0
                : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
            final pct = _dragValue ?? actualPct;

            return Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return GestureDetector(
                      onTapDown: (d) => _updateDrag(d.localPosition.dx, width, duration),
                      onTapUp: (_) => _commitDrag(duration),
                      onTapCancel: _cancelDrag,
                      onHorizontalDragUpdate: (d) =>
                          _updateDrag(d.localPosition.dx, width, duration),
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
                          child: Container(color: const Color(0xFFA0A0A0)),
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
                      position.asCompact,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      duration.asCompact,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
