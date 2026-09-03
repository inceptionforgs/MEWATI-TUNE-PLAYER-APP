import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/models/song.dart';

void main() {
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

    test('fromJson parses is_premium from num/String forms without throwing', () {
      expect(Song.fromJson({'is_premium': 1}).isPremium, isTrue);
      expect(Song.fromJson({'is_premium': 0}).isPremium, isFalse);
      expect(Song.fromJson({'is_premium': 'true'}).isPremium, isTrue);
      expect(Song.fromJson({'is_premium': 'false'}).isPremium, isFalse);
    });

    group('mapValidRows', () {
      test('skips a row with an empty id instead of throwing', () {
        final rows = [
          {'id': '', 'audio_url': 'https://example.com/a.mp3', 'title': 'A'},
          {'id': 'good-1', 'audio_url': 'https://example.com/b.mp3', 'title': 'B'},
        ];

        final songs = Song.mapValidRows(rows);

        expect(songs.length, 1);
        expect(songs.first.id, 'good-1');
      });

      test('skips a row with an empty/whitespace audioUrl instead of throwing', () {
        final rows = [
          {'id': 'song-1', 'audio_url': '', 'title': 'A'},
          {'id': 'song-2', 'audio_url': '   ', 'title': 'B'},
          {'id': 'song-3', 'audio_url': 'https://example.com/c.mp3', 'title': 'C'},
        ];

        final songs = Song.mapValidRows(rows);

        expect(songs.map((s) => s.id), ['song-3']);
      });

      test('skips a row that is not a Map instead of throwing', () {
        final rows = <dynamic>[
          'not a map',
          {'id': 'song-1', 'audio_url': 'https://example.com/a.mp3', 'title': 'A'},
        ];

        final songs = Song.mapValidRows(rows);

        expect(songs.length, 1);
        expect(songs.first.id, 'song-1');
      });

      test('keeps all rows valid rows and returns them in order', () {
        final rows = [
          {'id': '1', 'audio_url': 'https://example.com/1.mp3', 'title': 'One'},
          {'id': '2', 'audio_url': 'https://example.com/2.mp3', 'title': 'Two'},
          {'id': '3', 'audio_url': 'https://example.com/3.mp3', 'title': 'Three'},
        ];

        final songs = Song.mapValidRows(rows);

        expect(songs.map((s) => s.id).toList(), ['1', '2', '3']);
      });
    });
  });
}
