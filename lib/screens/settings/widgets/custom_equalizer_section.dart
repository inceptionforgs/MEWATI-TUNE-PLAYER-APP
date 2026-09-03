import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/equalizer_service.dart';

/// Custom Equalizer sub-section of Advance Settings (File 31a).
///
/// 5-band gain sliders (matching whatever bands the device's real
/// AndroidEqualizer reports — no hardcoded frequency list) + a separate
/// Bass Boost slider (the loudness enhancer's single target gain) +
/// Reset to Default.
///
/// Surround Sound and Mono Audio were intentionally left out: just_audio
/// has no API for either on any platform, so there is nothing real to
/// wire a toggle to.
class CustomEqualizerSection extends StatefulWidget {
  const CustomEqualizerSection({super.key});

  @override
  State<CustomEqualizerSection> createState() => _CustomEqualizerSectionState();
}

class _CustomEqualizerSectionState extends State<CustomEqualizerSection> {
  final _equalizerService = EqualizerService();

  bool _loading = true;
  bool _supported = true;
  // NEW: distinguishes "device genuinely has no AndroidEqualizer" from
  // "the native call just never responded" so the message shown below
  // is accurate either way.
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

    // NEW: getBandParameters() awaits just_audio's native
    // `equalizer.parameters` getter, which only resolves once the
    // AndroidEqualizer is actually attached to a live AudioPipeline. If
    // that never happens (no player loaded yet on this device, or the
    // native effect fails to attach), the Future never completes and the
    // spinner in build() below spins forever. A hard timeout guarantees
    // this screen always settles into either the sliders or the
    // "not available" message.
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

    // Apply the saved custom values live right away, and switch the
    // active preset to 'custom' so what the sliders show matches what's
    // actually playing (matches File 31's "persist the equalizer preset
    // choice, not just the theme" requirement).
    for (int i = 0; i < params.bands.length; i++) {
      await _equalizerService.setBandGain(i, saved.bandGains[i]);
    }
    await _equalizerService.setBassBoost(saved.bassBoostDb);

    if (!mounted) return;
    final themeProvider = context.read<ThemeProvider>();
    if (themeProvider.eqPreset != 'custom') {
      await themeProvider.setEqPreset('custom');
    }

    if (!mounted) return;
    setState(() {
      _params = params;
      _bandGains = List<double>.from(saved.bandGains);
      _bassBoost = saved.bassBoostDb;
      _loading = false;
    });
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
              // CHANGED: previously always said "only available on Android
              // devices" even when running ON Android and the real problem
              // was the native call timing out.
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

        // 5-band sliders, laid out horizontally like a hardware EQ.
        SizedBox(
          height: 220,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(params.bands.length, (index) {
              final band = params.bands[index];
              final gain = _bandGains.length > index ? _bandGains[index] : 0.0;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      '${gain.toStringAsFixed(1)}dB',
                      style: TextStyle(color: t.textSecondary, fontSize: 10),
                    ),
                    Expanded(
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
                            },
                            onChangeEnd: (_) => _persist(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFrequency(band.centerFrequency.round()),
                      style: TextStyle(color: t.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        // Bass Boost — a separate single control (the loudness enhancer),
        // not one of the 5 EQ bands.
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
