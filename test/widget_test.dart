import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mewati_tune_player/core/utils/debouncer.dart';
import 'package:mewati_tune_player/models/song.dart';

void main() {
  testWidgets('App basic widget test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Mewati Tune Player'),
          ),
        ),
      ),
    );
    expect(find.text('Mewati Tune Player'), findsOneWidget);
  });

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
  });

  group('Song model', () {
    test('fromJson/toJson round trip preserves data', () {
      final json = {
        'id': 'song-1',
        'title': 'Test Song',
        'singer_id': 'singer-1',
        'category': 'Folk',
        'audio_url': 'https://example.com/audio.mp3',
        'cover_image_url': 'https://example.com/cover.jpg',
        'duration': 180,
        'play_count': 42,
        'like_count': 7,
        'is_premium': false,
      };

      final song = Song.fromJson(json);
      final roundTripped = song.toJson();

      expect(roundTripped['id'], json['id']);
      expect(roundTripped['title'], json['title']);
      expect(roundTripped['audio_url'], json['audio_url']);
      expect(roundTripped['play_count'], json['play_count']);
      expect(roundTripped['like_count'], json['like_count']);
      expect(roundTripped['is_premium'], json['is_premium']);
    });

    test('fromJson handles missing/null fields with sane defaults', () {
      final song = Song.fromJson({});
      expect(song.title, 'Unknown Song');
      expect(song.playCount, 0);
      expect(song.likeCount, 0);
      expect(song.isPremium, isFalse);
    });
  });
}