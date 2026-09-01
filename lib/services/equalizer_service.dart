import 'dart:io' show Platform;
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

  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();

  bool _isInitialized = false;

  static const double _mewatiBassLoudnessGainDb = 2.0;
  static const double _maxLoudnessGainDb = 6.0;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) {
      print('EqualizerService: skipped, unsupported platform (${Platform.operatingSystem})');
      return;
    }
    try {
      await equalizer.setEnabled(true);
      await loudnessEnhancer.setEnabled(true);
      _isInitialized = true;
    } catch (e) {
      print('EqualizerService init error: $e');
    }
  }

  Future<void> applyPreset(String preset) async {
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
    if (!_isInitialized) return;
    try {
      final params = await equalizer.parameters;
      for (final band in params.bands) {
        final rawGain = _gainForBand(mode, band.centerFrequency.toDouble());
        final clamped = rawGain.clamp(params.minDecibels, params.maxDecibels);
        await band.setGain(clamped);
      }
      final requested = (mode == SoundMode.mewatiBass) ? _mewatiBassLoudnessGainDb : 0.0;
      final safeLoudness = requested.clamp(0.0, _maxLoudnessGainDb);
      await loudnessEnhancer.setTargetGain(safeLoudness);
    } catch (e) {
      print('EqualizerService applyPreset error: $e');
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