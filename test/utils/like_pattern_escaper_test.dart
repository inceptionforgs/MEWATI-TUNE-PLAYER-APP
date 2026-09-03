import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/core/utils/like_pattern_escaper.dart';

void main() {
  group('escapeLikePattern', () {
    test('escapes a literal "100%" input', () {
      expect(escapeLikePattern('100%'), r'100\%');
    });

    test('escapes percent signs', () {
      expect(escapeLikePattern('50% off'), r'50\% off');
    });

    test('escapes underscores', () {
      expect(escapeLikePattern('some_song_title'), r'some\_song\_title');
    });

    test('escapes backslashes', () {
      expect(escapeLikePattern(r'a\b'), r'a\\b');
    });

    test('escapes backslash before percent/underscore so escaping cannot be bypassed', () {
      // Order matters: backslashes must be escaped FIRST, otherwise a
      // literal backslash typed by the user could combine with the
      // escaping backslash we add for % or _ and change the meaning of
      // the pattern sent to Postgres.
      expect(escapeLikePattern(r'50%_off\test'), r'50\%\_off\\test');
    });

    test('leaves ordinary characters (including quotes) untouched', () {
      expect(escapeLikePattern("mewati song's title"), "mewati song's title");
      expect(escapeLikePattern('plain text'), 'plain text');
    });

    test('handles an empty string', () {
      expect(escapeLikePattern(''), '');
    });
  });
}
