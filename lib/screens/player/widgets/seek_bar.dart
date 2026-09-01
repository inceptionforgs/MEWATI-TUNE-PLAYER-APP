import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/theme_provider.dart';

class SeekBar extends StatefulWidget {
  const SeekBar({Key? key}) : super(key: key);

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = context.watch<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final duration = playerProvider.duration ?? Duration.zero;
    final position = playerProvider.position;
    final actualPct = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final pct = _dragValue ?? actualPct;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.28),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _fmt(position),
              style: TextStyle(
                color: t.textPrimary.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _fmt(duration),
              style: TextStyle(
                color: t.textPrimary.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}