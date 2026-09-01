import 'package:flutter/foundation.dart';
import '../services/sleep_timer_service.dart';

class SleepTimerProvider extends ChangeNotifier {
  final SleepTimerService _sleepTimerService = SleepTimerService();

  Duration? _remaining;
  bool _isFading = false;

  Duration? get remaining => _remaining;
  bool get isActive => _sleepTimerService.isActive;
  bool get isFading => _isFading;

  void start(Duration duration) {
    _sleepTimerService.start(
      duration,
      onTick: () {
        _remaining = _sleepTimerService.remaining;
        _isFading = _sleepTimerService.isFading;
        notifyListeners();
      },
      onComplete: () {
        _remaining = Duration.zero;
        _isFading = false;
        notifyListeners();
      },
    );
    _remaining = duration;
    _isFading = false;
    notifyListeners();
  }

  void cancel() {
    _sleepTimerService.cancel();
    _remaining = null;
    _isFading = false;
    notifyListeners();
  }
}