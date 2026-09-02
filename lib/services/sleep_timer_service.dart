import 'dart:async';
import 'package:flutter/foundation.dart';
import 'player_service.dart';

class SleepTimerService {
  static final SleepTimerService _instance = SleepTimerService._internal();
  factory SleepTimerService() => _instance;
  SleepTimerService._internal();

  final PlayerService _playerService = PlayerService();

  Timer? _timer;
  Duration? _totalDuration;
  Duration? _remaining;
  bool _isFading = false;
  VoidCallback? _onTick;
  VoidCallback? _onComplete;
  int _generation = 0; // token to invalidate stale callbacks

  bool get isActive => _timer != null;
  Duration? get remaining => _remaining;
  Duration? get totalDuration => _totalDuration;
  bool get isFading => _isFading;

  void start(
    Duration duration, {
    VoidCallback? onTick,
    VoidCallback? onComplete,
  }) {
    cancel(); // clean up any previous timer
    final gen = ++_generation;

    _totalDuration = duration;
    _remaining = duration;
    _onTick = onTick;
    _onComplete = onComplete;
    _isFading = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Ignore callbacks from a previous generation.
      if (gen != _generation) {
        timer.cancel();
        return;
      }

      if (_remaining == null) return;

      _remaining = _remaining! - const Duration(seconds: 1);

      // If countdown reaches zero, stop playback and finish.
      if (_remaining! <= Duration.zero) {
        timer.cancel();
        _timer = null;
        _remaining = Duration.zero;

        // Ensure playback stops even if fade didn't run or failed.
        _playerService.pause();

        _isFading = false;
        _onComplete?.call();
        return;
      }

      // Start fade-out when 30 seconds or less remain and total > 30s.
      if (!_isFading &&
          _remaining! <= const Duration(seconds: 30) &&
          _totalDuration! > const Duration(seconds: 30)) {
        _isFading = true;
        _playerService.fadeOut();
      }

      _onTick?.call();
    });
  }

  void cancel() {
    _generation++; // invalidates any pending periodic callback
    _timer?.cancel();
    _timer = null;
    _remaining = null;
    _totalDuration = null;
    if (_isFading) {
      _playerService.cancelFadeOut();
      _isFading = false;
    }
  }
}