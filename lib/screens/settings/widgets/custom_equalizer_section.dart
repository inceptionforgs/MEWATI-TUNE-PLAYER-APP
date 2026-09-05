import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/equalizer_service.dart';

class CustomEqualizerSection extends StatefulWidget {
  const CustomEqualizerSection({super.key});

  @override
  State<CustomEqualizerSection> createState() => _CustomEqualizerSectionState();
}

class _CustomEqualizerSectionState extends State<CustomEqualizerSection> {
  final _equalizerService = EqualizerService();

  bool _loading = true;
  bool _supported = true;
  bool _timedOut = false;
  AndroidEqualizerParameters? _params;
  List<double> _bandGains = [];
  double _bassBoost = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_equalizerService.isSupported) {
      setState(() {
        _supported = false;
        _loading = false;
      });
      return;
    }

    AndroidEqualizerParameters? params;
    try {
      params = await _equalizerService.getBandParameters().timeout(
        const Duration(seconds: 4),
      );
    } on TimeoutException {
      params = null;
      _timedOut = true;
    }

    if (params == null) {
      if (!mounted) return;
      setState(() {
        _supported = false;
        _loading = false;
      });
      return;
    }

    final saved = await _equalizerService.loadPersistedCustomEq(
      bandCount: params.bands.length,
    );

    // TabBarView also mounts this widget when opening Custom Theme.
    // Only push saved custom EQ onto the live pipeline if Custom is
    // already the active preset — otherwise a theme-only visit would
    // silently replace Mewati Bass / Vocal / etc.
    final applyLive =
        mounted && context.read<ThemeProvider>().eqPreset == 'custom';
    if (applyLive) {
      for (int i = 0; i < params.bands.length; i++) {
        await _equalizerService.setBandGain(i, saved.bandGains[i]);
      }
      await _equalizerService.setBassBoost(saved.bassBoostDb);
    }

    if (!mounted) return;
    setState(() {
      _params = params;
      _bandGains = List<double>.from(saved.bandGains);
      _bassBoost = saved.bassBoostDb;
      _loading = false;
    });
  }

  void _markCustomIfNeeded() {
    final themeProvider = context.read<ThemeProvider>();
    if (themeProvider.eqPreset != 'custom') {
      themeProvider.setEqPreset('custom');
    }
  }

  Future<void> _persist() async {
    await _equalizerService.persistCustomEq(
      bandGains: _bandGains,
      bassBoostDb: _bassBoost,
    );
  }

  Future<void> _resetToDefault() async {
    await _equalizerService.resetCustomEq();
    if (!mounted) return;
    setState(() {
      _bandGains = List<double>.filled(_bandGains.length, 0.0);
      _bassBoost = 0.0;
    });
  }

  String _formatFrequency(int hz) {
    if (hz >= 1000) {
      final khz = hz / 1000;
      return khz == khz.roundToDouble()
          ? '${khz.round()}kHz'
          : '${khz.toStringAsFixed(1)}kHz';
    }
    return '${hz}Hz';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: t.accent)),
      );
    }

    if (!_supported || _params == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _timedOut
              ? 'Custom Equalizer could not be loaded on this device. Try playing a song first, then reopen this screen.'
              : 'Custom Equalizer is only available on Android devices.',
          style: TextStyle(color: t.textSecondary),
        ),
      );
    }

    final params = _params!;
    final minDb = params.minDecibels;
    final maxDb = params.maxDecibels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Custom Equalizer',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Drag each band to shape the sound. Changes apply instantly.',
          style: TextStyle(color: t.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 220,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(params.bands.length, (index) {
              final band = params.bands[index];
              final gain = _bandGains.length > index ? _bandGains[index] : 0.0;
              final frequencyLabel = _formatFrequency(band.centerFrequency.round());
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '${gain.toStringAsFixed(1)}dB',
                      style: TextStyle(color: t.textSecondary, fontSize: 10),
                    ),
                    Expanded(
                      child: Semantics(
                        label: '$frequencyLabel band',
                        value: '${gain.toStringAsFixed(1)}dB',
                        increasedValue: '${(gain + 1).clamp(minDb, maxDb).toStringAsFixed(1)}dB',
                        decreasedValue: '${(gain - 1).clamp(minDb, maxDb).toStringAsFixed(1)}dB',
                        slider: true,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: t.accent,
                              inactiveTrackColor: t.surface,
                              thumbColor: t.accent,
                              overlayColor: t.accent.withOpacity(0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: gain.clamp(minDb, maxDb),
                              min: minDb,
                              max: maxDb,
                              onChanged: (value) {
                                setState(() {
                                  _bandGains[index] = value;
                                });
                                _equalizerService.setBandGain(index, value);
                                _markCustomIfNeeded();
                              },
                              onChangeEnd: (_) => _persist(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      frequencyLabel,
                      style: TextStyle(color: t.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bass Boost',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_bassBoost.toStringAsFixed(1)}dB',
              style: TextStyle(color: t.textSecondary, fontSize: 12),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: t.accent,
            inactiveTrackColor: t.surface,
            thumbColor: t.accent,
            overlayColor: t.accent.withOpacity(0.2),
          ),
          child: Slider(
            value: _bassBoost.clamp(0.0, EqualizerService.maxBassBoostDb),
            min: 0.0,
            max: EqualizerService.maxBassBoostDb,
            onChanged: (value) {
              setState(() => _bassBoost = value);
              _equalizerService.setBassBoost(value);
              _markCustomIfNeeded();
            },
            onChangeEnd: (_) => _persist(),
          ),
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton(
            onPressed: _resetToDefault,
            style: OutlinedButton.styleFrom(
              foregroundColor: t.textPrimary,
              side: BorderSide(color: t.textSecondary),
            ),
            child: const Text('Reset to Default'),
          ),
        ),
      ],
    );
  }
}