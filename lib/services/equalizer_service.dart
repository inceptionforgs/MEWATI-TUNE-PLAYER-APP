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

  // NOTE: just_audio's AndroidEqualizer/AndroidLoudnessEnhancer only exist
  // on Android, and only support per-band gain (EQ) + a single loudness
  // ("bass boost") target gain. There is no Surround Sound or Mono Audio
  // control available through just_audio on any platform, so those two
  // controls were intentionally left out of Advance Settings — there is
  // nothing real to wire them to, and a fake toggle would be exactly the
  // kind of client-only "looks like it works" gate this project avoids
  // elsewhere (see File 40).
  AndroidEqualizer? _equalizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  AndroidEqualizer? get equalizer => _equalizer;
  AndroidLoudnessEnhancer? get loudnessEnhancer => _loudnessEnhancer;

  bool _isInitialized = false;
  bool get isSupported => Platform.isAndroid;

  static const double _mewatiBassLoudnessGainDb = 2.0;
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
      // Construct these lazily, only on Android — building them on other
      // platforms is what used to risk crashing playback on init.
      _equalizer = AndroidEqualizer();
      _loudnessEnhancer = AndroidLoudnessEnhancer();
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
      if (!_isInitialized) return; // platform unsupported or init failed
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
      final requested = (mode == SoundMode.mewatiBass) ? _mewatiBassLoudnessGainDb : 0.0;
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

  // ---------------------------------------------------------------------
  // Custom 5-band EQ + bass boost (Advance Settings, File 31)
  // ---------------------------------------------------------------------

  /// Returns the live band parameters (frequency + min/max/current gain)
  /// so the UI can build sliders that match the device's actual equalizer.
  /// Returns null if unsupported/not yet initialized.
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

  /// Sets a single band's gain (dB) immediately, live, without touching the
  /// others. The caller is responsible for calling [persistCustomEq] once
  /// the user is done adjusting (e.g. debounced), not on every frame.
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

  /// Bass boost is a single loudness-enhancer target gain, separate from
  /// the 5 EQ bands, clamped to [0, maxBassBoostDb].
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

  /// Persists the current custom band gains + bass boost to
  /// SharedPreferences, so they can be re-applied on next launch when the
  /// saved preset is 'custom'.
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

  /// Resets custom EQ to flat (0 dB every band) + 0 bass boost, both live
  /// and in storage. Does not change which preset is selected — the caller
  /// (Advance Settings screen) decides whether to also switch the saved
  /// preset back to 'normal'.
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
