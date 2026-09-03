import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mewati_tune_player/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('fires action after the delay', () {
      fakeAsync((async) {
        var fired = false;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 500));
        debouncer.run(() => fired = true);

        async.elapse(const Duration(milliseconds: 499));
        expect(fired, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(fired, isTrue);
      });
    });

    test('cancels previous call if run again before delay elapses', () {
      fakeAsync((async) {
        var callCount = 0;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 500));

        debouncer.run(() => callCount++);
        async.elapse(const Duration(milliseconds: 300));
        debouncer.run(() => callCount++);

        async.elapse(const Duration(milliseconds: 300));
        expect(callCount, 0);

        async.elapse(const Duration(milliseconds: 200));
        expect(callCount, 1);
      });
    });

    test('cancel() stops a pending call from firing', () {
      fakeAsync((async) {
        var fired = false;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 500));
        debouncer.run(() => fired = true);
        debouncer.cancel();

        async.elapse(const Duration(seconds: 2));
        expect(fired, isFalse);
      });
    });
  });
}
