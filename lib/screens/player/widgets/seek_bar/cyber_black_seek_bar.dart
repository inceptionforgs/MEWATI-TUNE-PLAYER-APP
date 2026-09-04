import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/extensions/duration_extensions.dart';
import '../../../../providers/player_provider.dart';
import '../../../../providers/theme_provider.dart';

/// Seek bar used for the Deep Black theme.
///
/// Content is currently identical to WalkmanOrangeSeekBar — this is a
/// pure file-separation step so Deep Black's seek bar can get its own
/// look later without touching the other themes.
class CyberBlackSeekBar extends StatefulWidget {
  const CyberBlackSeekBar({Key? key}) : super(key: key);

  @override
  State<CyberBlackSeekBar> createState() => _CyberBlackSeekBarState();
}

class _CyberBlackSeekBarState extends State<CyberBlackSeekBar> {
  double? _dragValue;

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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.5),
                    overlayShape: SliderComponentShape.noOverlay,
                    activeTrackColor: t.textPrimary,
                    inactiveTrackColor: t.textPrimary.withOpacity(0.28),
                    thumbColor: t.textPrimary,
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
                      position.asCompact,
                      style: TextStyle(
                        color: t.textPrimary.withOpacity(0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      duration.asCompact,
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
          },
        );
      },
    );
  }
}
