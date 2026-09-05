import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundMode {
  normal,
  mewatiBass,
  beatsMode,
  vocalBoost,
  trebleBoost,
  custom,
}

const _customEqBandsKey = 'custom_eq_band_gains';
const _customEqBassKey = 'custom_eq_bass_boost';

class EqualizerService {
  static final EqualizerService _instance = EqualizerService._internal();
  factory EqualizerService() => _instance;
  EqualizerService._internal();

  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  AndroidEqualizer? get equalizer => _equalizer;
  AndroidLoudnessEnhancer? get loudnessEnhancer => _loudnessEnhancer;

  /// Lazily creates the Android effect instances (safe to call before
  /// [init]) and returns them for [AudioPipeline.androidAudioEffects].
  /// Empty on non-Android platforms.
  List<AndroidAudioEffect> get androidAudioEffects {
    if (!Platform.isAndroid) return const [];
    _equalizer ??= AndroidEqualizer();
    _loudnessEnhancer ??= AndroidLoudnessEnhancer();
    return [_equalizer!, _loudnessEnhancer!];
  }

  bool _isInitialized = false;
  bool get isSupported => Platform.isAndroid;

  static const double _mewatiBassLoudnessGainDb = 2.0;

  /// Sony Ericsson Mega Bass used extra "weight" on top of the EQ shelf.
  /// LoudnessEnhancer is the closest effect this pipeline exposes.
  static const double _megaBassLoudnessGainDb = 3.0;

  static const double maxBassBoostDb = 6.0;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) {
      debugPrint(
        'EqualizerService: skipped, unsupported platform (${Platform.operatingSystem})',
      );
      return;
    }
    try {
      _equalizer ??= AndroidEqualizer();
      _loudnessEnhancer ??= AndroidLoudnessEnhancer();
      await _equalizer!.setEnabled(true);
      await _loudnessEnhancer!.setEnabled(true);
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService init error: $e');
    }
  }

  Future<void> applyPreset(String preset) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }

    if (preset == 'custom') {
      await _applyPersistedCustomEq();
      return;
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
    final equalizer = _equalizer;
    final loudnessEnhancer = _loudnessEnhancer;
    if (equalizer == null || loudnessEnhancer == null) return;

    try {
      final params = await equalizer.parameters;
      for (final band in params.bands) {
        final rawGain = _gainForBand(mode, band.centerFrequency.toDouble());
        final clamped = rawGain.clamp(params.minDecibels, params.maxDecibels);
        await band.setGain(clamped);
      }
      final requested = switch (mode) {
        SoundMode.mewatiBass => _mewatiBassLoudnessGainDb,
        SoundMode.beatsMode => _megaBassLoudnessGainDb,
        _ => 0.0,
      };
      final safeLoudness = requested.clamp(0.0, maxBassBoostDb);
      await loudnessEnhancer.setTargetGain(safeLoudness);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService applySoundMode error: $e');
    }
  }

  double _gainForBand(SoundMode mode, double hz) {
    switch (mode) {
      case SoundMode.normal:
      case SoundMode.custom:
        return 0.0;
      case SoundMode.mewatiBass:
        if (hz <= 80) return 10.0;
        if (hz <= 150) return 7.0;
        if (hz <= 300) return 0.0;
        if (hz <= 1000) return -2.0;
        if (hz <= 6000) return 0.0;
        return 2.5;
      case SoundMode.beatsMode:
        // Sony Ericsson Mega Bass-inspired loudness contour.
        // Analog/phone MB was NOT a sub-only shelf:
        //   • fat 60–80 Hz
        //   • punch at ~200–250 Hz (small-speaker "felt" bass)
        //   • slight lower-mid dip so it doesn't turn to mud
        //   • vocals left alone (old Beats Mode cut 150–2000 Hz by -2.5)
        //   • treble air, same trick analog MB used so bass doesn't dull the mix
        // Typical Android 5-band centres: ~60 / 230 / 910 / 3600 / 14000 Hz.
        if (hz <= 70) return 9.0;
        if (hz <= 120) return 8.0;
        if (hz <= 250) return 5.5;
        if (hz <= 400) return 1.5;
        if (hz <= 900) return -1.5;
        if (hz <= 2500) return 0.0;
        if (hz <= 6000) return 2.0;
        return 3.5;
      case SoundMode.vocalBoost:
        if (hz >= 1000 && hz <= 4000) return 5.5;
        if (hz < 300) return -2.0;
        return 0.5;
      case SoundMode.trebleBoost:
        if (hz >= 6000) return 6.0;
        return 0.0;
    }
  }

  Future<AndroidEqualizerParameters?> getBandParameters() async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return null;
    }
    try {
      return await _equalizer?.parameters;
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService getBandParameters error: $e');
      return null;
    }
  }

  Future<void> setBandGain(int bandIndex, double gainDb) async {
    final params = await getBandParameters();
    if (params == null || bandIndex < 0 || bandIndex >= params.bands.length) {
      return;
    }
    try {
      final clamped = gainDb.clamp(params.minDecibels, params.maxDecibels);
      await params.bands[bandIndex].setGain(clamped);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService setBandGain error: $e');
    }
  }

  Future<void> setBassBoost(double gainDb) async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }
    try {
      final clamped = gainDb.clamp(0.0, maxBassBoostDb);
      await _loudnessEnhancer?.setTargetGain(clamped);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService setBassBoost error: $e');
    }
  }

  Future<void> persistCustomEq({
    required List<double> bandGains,
    required double bassBoostDb,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customEqBandsKey, jsonEncode(bandGains));
      await prefs.setDouble(_customEqBassKey, bassBoostDb);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService persistCustomEq error: $e');
    }
  }

  Future<({List<double> bandGains, double bassBoostDb})> loadPersistedCustomEq({
    required int bandCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customEqBandsKey);
      List<double> gains;
      if (raw != null) {
        final decoded = (jsonDecode(raw) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        gains = List<double>.generate(
          bandCount,
          (i) => i < decoded.length ? decoded[i] : 0.0,
        );
      } else {
        gains = List<double>.filled(bandCount, 0.0);
      }
      final bass = prefs.getDouble(_customEqBassKey) ?? 0.0;
      return (bandGains: gains, bassBoostDb: bass);
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService loadPersistedCustomEq error: $e');
      return (bandGains: List<double>.filled(bandCount, 0.0), bassBoostDb: 0.0);
    }
  }

  Future<void> _applyPersistedCustomEq() async {
    final params = await getBandParameters();
    if (params == null) return;
    final saved = await loadPersistedCustomEq(bandCount: params.bands.length);
    try {
      for (int i = 0; i < params.bands.length; i++) {
        final clamped = saved.bandGains[i].clamp(params.minDecibels, params.maxDecibels);
        await params.bands[i].setGain(clamped);
      }
      await _loudnessEnhancer?.setTargetGain(saved.bassBoostDb.clamp(0.0, maxBassBoostDb));
    } catch (e) {
      if (kDebugMode) debugPrint('EqualizerService _applyPersistedCustomEq error: $e');
    }
  }

  Future<void> resetCustomEq() async {
    final params = await getBandParameters();
    if (params != null) {
      try {
        for (final band in params.bands) {
          await band.setGain(0.0);
        }
        await _loudnessEnhancer?.setTargetGain(0.0);
      } catch (e) {
        if (kDebugMode) debugPrint('EqualizerService resetCustomEq error: $e');
      }
    }
    await persistCustomEq(
      bandGains: List<double>.filled(params?.bands.length ?? 5, 0.0),
      bassBoostDb: 0.0,
    );
  }
}