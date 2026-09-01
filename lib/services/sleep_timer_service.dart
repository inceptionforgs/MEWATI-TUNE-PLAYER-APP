import 'dart:async';
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

  bool get isActive => _timer != null;
  Duration? get remaining => _remaining;
  bool get isFading => _isFading;

  void start(
    Duration duration, {
    VoidCallback? onTick,
    VoidCallback? onComplete,
  }) {
    cancel();

    _totalDuration = duration;
    _remaining = duration;
    _onTick = onTick;
    _onComplete = onComplete;
    _isFading = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining == null) return;

      _remaining = _remaining! - const Duration(seconds: 1);

      if (_remaining! <= Duration.zero) {
        timer.cancel();
        _timer = null;
        _remaining = Duration.zero;
        _onComplete?.call();
        return;
      }

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