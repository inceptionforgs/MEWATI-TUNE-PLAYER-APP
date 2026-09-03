import 'package:flutter/foundation.dart';
import '../services/sleep_timer_service.dart';

class SleepTimerProvider extends ChangeNotifier {
  final SleepTimerService _sleepTimerService = SleepTimerService();

  Duration? _remaining;
  Duration? _totalDuration;
  bool _isFading = false;

  Duration? get remaining => _remaining;
  Duration? get totalDuration => _totalDuration;
  bool get isActive => _sleepTimerService.isActive;
  bool get isFading => _isFading;

  void start(Duration duration) {
    _sleepTimerService.start(
      duration,
      onTick: () {
        _remaining = _sleepTimerService.remaining;
        _totalDuration = _sleepTimerService.totalDuration;
        _isFading = _sleepTimerService.isFading;
        notifyListeners();
      },
      onComplete: () {
        _remaining = null;
        _totalDuration = null;
        _isFading = false;
        notifyListeners();
      },
    );
    _remaining = duration;
    _totalDuration = duration;
    _isFading = false;
    notifyListeners();
  }

  void cancel() {
    _sleepTimerService.cancel();
    _remaining = null;
    _totalDuration = null;
    _isFading = false;
    notifyListeners();
  }
}
