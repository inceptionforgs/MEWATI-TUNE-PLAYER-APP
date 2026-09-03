import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/core/utils/queue_builder.dart';
import 'package:mewati_tune_player/models/song.dart';

Song _song(String id, {String audioUrl = 'https://example.com/a.mp3'}) {
  return Song(id: id, title: 'Song $id', audioUrl: audioUrl);
}

void main() {
  group('QueueBuilder.build', () {
    test('keeps list length > 1 when every song has a valid remote URL', () {
      final songs = [_song('1'), _song('2'), _song('3')];

      final result = QueueBuilder.build(songs: songs, startIndex: 0);

      expect(result.songs.length, 3);
      expect(result.songs.length, greaterThan(1));
    });

    test('skips a song with an invalid/empty audioUrl instead of throwing', () {
      final songs = [
        _song('1'),
        _song('2', audioUrl: ''),
        _song('3', audioUrl: 'not a url with spaces'),
        _song('4'),
      ];

      final result = QueueBuilder.build(songs: songs, startIndex: 0);

      expect(result.songs.map((s) => s.id).toList(), ['1', '4']);
    });

    test('keeps a song with no remote URL if it has a verified local file', () {
      final songs = [_song('1', audioUrl: ''), _song('2')];

      final result = QueueBuilder.build(
        songs: songs,
        startIndex: 0,
        locallyAvailableSongIds: {'1'},
      );

      expect(result.songs.map((s) => s.id).toSet(), {'1', '2'});
    });

    test('throws a StateError when every song is unplayable', () {
      final songs = [_song('1', audioUrl: ''), _song('2', audioUrl: 'bad url')];

      expect(
        () => QueueBuilder.build(songs: songs, startIndex: 0),
        throwsStateError,
      );
    });

    test('throws an ArgumentError when the input playlist is empty', () {
      expect(
        () => QueueBuilder.build(songs: [], startIndex: 0),
        throwsArgumentError,
      );
    });

    test('remaps startIndex to the filtered list when earlier songs are dropped', () {
      final songs = [_song('1', audioUrl: ''), _song('2'), _song('3')];

      // Original index 2 ("3") should map to index 1 once song "1" is
      // filtered out.
      final result = QueueBuilder.build(songs: songs, startIndex: 2);

      expect(result.songs[result.startIndex].id, '3');
    });

    test('caps the queue to windowSize for a library larger than the window', () {
      final songs = List.generate(100, (i) => _song('$i'));

      final result = QueueBuilder.build(
        songs: songs,
        startIndex: 50,
        windowSize: 10,
      );

      expect(result.songs.length, 10);
      expect(result.songs[result.startIndex].id, '50');
    });

    test('window stays centered around startIndex when there is room on both sides', () {
      final songs = List.generate(100, (i) => _song('$i'));

      final result = QueueBuilder.build(
        songs: songs,
        startIndex: 50,
        windowSize: 10,
      );

      // The window should not simply start from song "0" — it should be
      // centered around song "50".
      expect(result.songs.first.id, isNot('0'));
      expect(result.songs.map((s) => s.id), contains('50'));
    });

    test('window clamps to the start of the list when startIndex is near 0', () {
      final songs = List.generate(100, (i) => _song('$i'));

      final result = QueueBuilder.build(
        songs: songs,
        startIndex: 0,
        windowSize: 10,
      );

      expect(result.songs.length, 10);
      expect(result.songs.first.id, '0');
      expect(result.songs[result.startIndex].id, '0');
    });

    test('window clamps to the end of the list when startIndex is near the end', () {
      final songs = List.generate(100, (i) => _song('$i'));

      final result = QueueBuilder.build(
        songs: songs,
        startIndex: 99,
        windowSize: 10,
      );

      expect(result.songs.length, 10);
      expect(result.songs.last.id, '99');
      expect(result.songs[result.startIndex].id, '99');
    });

    test('default windowSize matches PlayerService.maxQueueWindow (60)', () {
      expect(QueueBuilder.maxQueueWindow, 60);

      final songs = List.generate(200, (i) => _song('$i'));
      final result = QueueBuilder.build(songs: songs, startIndex: 0);

      expect(result.songs.length, 60);
    });

    test('does not window a library smaller than or equal to windowSize', () {
      final songs = List.generate(60, (i) => _song('$i'));

      final result = QueueBuilder.build(songs: songs, startIndex: 30);

      expect(result.songs.length, 60);
      expect(result.songs[result.startIndex].id, '30');
    });
  });
}
