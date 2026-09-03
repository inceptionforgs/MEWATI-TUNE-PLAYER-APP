import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/models/singer.dart';

void main() {
  group('Singer model', () {
    test('fromJson provides defaults for missing fields', () {
      final singer = Singer.fromJson({});
      expect(singer.id, '');
      expect(singer.name, 'Unknown Singer');
      expect(singer.songCount, isNull);
    });

    test('fromJson parses song_count from a plain int', () {
      final singer = Singer.fromJson({'id': 's1', 'name': 'A', 'song_count': 12});
      expect(singer.songCount, 12);
    });

    test('fromJson parses song_count from a bigint/num (e.g. Postgres bigint) without crashing', () {
      // Supabase can return bigint columns as a num/double rather than a
      // plain int — a direct `as int?` cast would throw here.
      final singer = Singer.fromJson({'id': 's1', 'name': 'A', 'song_count': 42.0});
      expect(singer.songCount, 42);
    });

    test('fromJson parses song_count from a numeric string', () {
      final singer = Singer.fromJson({'id': 's1', 'name': 'A', 'song_count': '7'});
      expect(singer.songCount, 7);
    });

    test('fromJson falls back to songs_count key when song_count is absent', () {
      final singer = Singer.fromJson({'id': 's1', 'name': 'A', 'songs_count': 9});
      expect(singer.songCount, 9);
    });

    test('toJson round trip preserves data', () {
      final singer = Singer(id: 's1', name: 'A Singer', bio: 'bio', photoUrl: 'url', songCount: 5);
      final json = singer.toJson();
      expect(json['id'], 's1');
      expect(json['name'], 'A Singer');
      expect(json['song_count'], 5);
    });
  });
}
