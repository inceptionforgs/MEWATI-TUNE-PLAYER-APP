import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum SoundMode {
  normal,
  mewatiBass,
  beatsMode,
  vocalBoost,
  trebleBoost,
}

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  // Construction guarded by Platform.isAndroid — these are now created
  // lazily and only on Android, so equalizer init failure can never
  // crash playback on other platforms.
  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  AndroidEqualizer? get equalizer {
    if (!Platform.isAndroid) return null;
    return _equalizer ??= AndroidEqualizer();
  }

  AndroidLoudnessEnhancer? get loudnessEnhancer {
    if (!Platform.isAndroid) return null;
    return _loudnessEnhancer ??= AndroidLoudnessEnhancer();
  }

  /// All Android audio effects for this service, ready to pass into
  /// AudioPipeline(androidAudioEffects: ...). Empty on non-Android.
  List<AndroidAudioEffect> get androidAudioEffects {
    if (!Platform.isAndroid) return const [];
    final eq = equalizer;
    final loud = loudnessEnhancer;
    return [
      if (eq != null) eq,
      if (loud != null) loud,
    ];
  }

  bool _isInitialized = false;

  static const double _mewatiBassLoudnessGainDb = 2.0;
  static const double _maxLoudnessGainDb = 6.0;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) {
      if (kDebugMode) {
        debugPrint('EqualizerService: skipped, unsupported platform (${Platform.operatingSystem})');
      }
      return;
    }
    final eq = equalizer;
    final loud = loudnessEnhancer;
    if (eq == null || loud == null) return;
    try {
      await eq.setEnabled(true);
      await loud.setEnabled(true);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EqualizerService init error: $e');
      }
    }
  }

  Future<void> applyPreset(String preset) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }

    SoundMode mode;
    switch (preset) {
      case 'normal':
        mode = SoundMode.normal;
        break;
      case 'mewati-bass':
        mode = SoundMode.mewatiBass;
        break;
      case 'beats':
        mode = SoundMode.beatsMode;
        break;
      case 'vocal':
        mode = SoundMode.vocalBoost;
        break;
      case 'treble':
        mode = SoundMode.trebleBoost;
        break;
      default:
        mode = SoundMode.normal;
    }
    await applySoundMode(mode);
  }

  Future<void> applySoundMode(SoundMode mode) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }
    final eq = equalizer;
    final loud = loudnessEnhancer;
    if (eq == null || loud == null) return;
    try {
      final params = await eq.parameters;
      for (final band in params.bands) {
        final rawGain = _gainForBand(mode, band.centerFrequency.toDouble());
        final clamped = rawGain.clamp(params.minDecibels, params.maxDecibels);
        await band.setGain(clamped);
      }
      final requested = (mode == SoundMode.mewatiBass) ? _mewatiBassLoudnessGainDb : 0.0;
      final safeLoudness = requested.clamp(0.0, _maxLoudnessGainDb);
      await loud.setTargetGain(safeLoudness);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('EqualizerService applyPreset error: $e');
      }
    }
  }

  double _gainForBand(SoundMode mode, double hz) {
    switch (mode) {
      case SoundMode.normal:
        return 0.0;
      case SoundMode.mewatiBass:
        if (hz <= 80) return 10.0;
        if (hz <= 150) return 7.0;
        if (hz <= 300) return 0.0;
        if (hz <= 1000) return -2.0;
        if (hz <= 6000) return 0.0;
        return 2.5;
      case SoundMode.beatsMode:
        if (hz <= 150) return 7.0;
        if (hz <= 2000) return -2.5;
        if (hz <= 8000) return 2.0;
        return 4.0;
      case SoundMode.vocalBoost:
        if (hz >= 1000 && hz <= 4000) return 5.5;
        if (hz < 300) return -2.0;
        return 0.5;
      case SoundMode.trebleBoost:
        if (hz >= 6000) return 6.0;
        return 0.0;
    }
  }
}
