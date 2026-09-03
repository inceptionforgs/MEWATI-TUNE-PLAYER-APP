import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mewati_tune_player/models/song.dart';
import 'package:mewati_tune_player/providers/downloads_provider.dart';
import 'package:mewati_tune_player/services/downloads_service.dart';

/// Fake DownloadsService used only in tests.
///
/// Implements (not extends) DownloadsService: the real class is a
/// factory-backed singleton with a private generative constructor, so it
/// cannot be subclassed from another file at all. `implements` only
/// requires matching its public method surface, which this fake does
/// entirely in-memory (no real files, no background_downloader plugin).
class FakeDownloadsService implements DownloadsService {
  final Set<String> existingFiles = {};
  final Map<String, Object> downloadErrorFor = {};
  final Map<String, Completer<void>> _pendingDownloads = {};

  int cancelCallCount = 0;
  int deleteCallCount = 0;
  String? lastDeletedAudioUrl;

  @override
  Future<String> getLocalSongPath(String songId, {String? audioUrl}) async {
    return '/fake/MewatiOfflineSongs/song_$songId';
  }

  @override
  Future<bool> isSongDownloaded(String songId, {String? audioUrl}) async {
    return existingFiles.contains(songId);
  }

  /// Makes the next downloadSong() call for [songId] block until the test
  /// calls [completePendingDownload] — used to simulate an in-flight
  /// download so cancel() can be exercised meaningfully.
  void holdDownload(String songId) {
    _pendingDownloads[songId] = Completer<void>();
  }

  void completePendingDownload(String songId) {
    _pendingDownloads.remove(songId)?.complete();
  }

  @override
  Future<void> downloadSong(
    Song song, {
    Function(double progress, int total)? onProgress,
  }) async {
    if (downloadErrorFor.containsKey(song.id)) {
      throw downloadErrorFor[song.id]!;
    }

    onProgress?.call(0.5, 100);

    final pending = _pendingDownloads[song.id];
    if (pending != null) {
      await pending.future;
    }

    onProgress?.call(1.0, 100);
    existingFiles.add(song.id);
  }

  @override
  Future<void> cancelDownload(String songId) async {
    cancelCallCount++;
    _pendingDownloads.remove(songId);
    existingFiles.remove(songId);
  }

  @override
  Future<void> deleteSong(String songId, {String? audioUrl}) async {
    deleteCallCount++;
    lastDeletedAudioUrl = audioUrl;
    existingFiles.remove(songId);
  }

  @override
  void dispose() {}
}

Song _song(String id, {String audioUrl = 'https://example.com/a.mp3'}) =>
    Song(id: id, title: 'Song $id', audioUrl: audioUrl);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadsProvider.downloadSong', () {
    test('start: marks the song as downloaded and offline-playable on success', () async {
      final fake = FakeDownloadsService();
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1');

      await provider.downloadSong(song);

      expect(provider.isDownloaded('s1'), isTrue);
      expect(provider.isDownloading('s1'), isFalse);
      // Proxy for "playable offline": the full Song is retained so a
      // player screen can queue it without a network round-trip.
      expect(provider.downloadedSongsList.map((s) => s.id), contains('s1'));
    });

    test('cancel: stops an in-flight download and clears its progress', () async {
      final fake = FakeDownloadsService()..holdDownload('s1');
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1');

      final future = provider.downloadSong(song); // not awaited: still in flight
      expect(provider.isDownloading('s1'), isTrue);

      await provider.cancelDownload('s1');
      fake.completePendingDownload('s1'); // let the fake's future resolve/no-op

      expect(fake.cancelCallCount, 1);
      expect(provider.isDownloading('s1'), isFalse);
      expect(provider.isDownloaded('s1'), isFalse);

      // Avoid an unhandled future in the test; downloadSong may still
      // resolve normally after cancel() since the fake doesn't hard-abort.
      await future.catchError((_) {});
    });

    test('missing file: a song not found on disk is never marked downloaded', () async {
      final fake = FakeDownloadsService(); // existingFiles stays empty
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1');

      await provider.checkExistingDownloads([song]);

      expect(provider.isDownloaded('s1'), isFalse);
    });

    test('corrupt file: a download that throws rethrows and leaves no partial state', () async {
      final fake = FakeDownloadsService()
        ..downloadErrorFor['s1'] = Exception('Downloaded file is empty.');
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1');

      await expectLater(provider.downloadSong(song), throwsException);

      expect(provider.isDownloaded('s1'), isFalse);
      expect(provider.isDownloading('s1'), isFalse);
    });
  });

  group('DownloadsProvider.removeDownload', () {
    test('deletes the correct file for an mp3 download', () async {
      final fake = FakeDownloadsService();
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1', audioUrl: 'https://cdn.example.com/audio/track.mp3');
      await provider.downloadSong(song);

      final ok = await provider.removeDownload('s1', audioUrl: song.audioUrl);

      expect(ok, isTrue);
      expect(fake.deleteCallCount, 1);
      expect(fake.lastDeletedAudioUrl, 'https://cdn.example.com/audio/track.mp3');
      expect(provider.isDownloaded('s1'), isFalse);
    });

    test('deletes the correct file for a non-mp3 (e.g. m4a) download', () async {
      final fake = FakeDownloadsService();
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s2', audioUrl: 'https://cdn.example.com/audio/track.m4a');
      await provider.downloadSong(song);

      final ok = await provider.removeDownload('s2', audioUrl: song.audioUrl);

      expect(ok, isTrue);
      expect(fake.lastDeletedAudioUrl, 'https://cdn.example.com/audio/track.m4a');
      expect(provider.isDownloaded('s2'), isFalse);
    });

    test('keeps the id on failure instead of silently forgetting the file', () async {
      final fake = FakeDownloadsService();
      final provider = DownloadsProvider(downloadsService: fake);
      final song = _song('s1');
      await provider.downloadSong(song);

      // Simulate the delete itself failing by overriding deleteSong via a
      // second fake that throws.
      final failingFake = _ThrowingDeleteDownloadsService();
      final provider2 = DownloadsProvider(downloadsService: failingFake);
      await provider2.downloadSong(_song('s2'));

      final ok = await provider2.removeDownload('s2', audioUrl: 'https://example.com/s2.mp3');

      expect(ok, isFalse);
      expect(provider2.isDownloaded('s2'), isTrue); // id kept, not silently dropped
    });
  });
}

class _ThrowingDeleteDownloadsService implements DownloadsService {
  final Set<String> existingFiles = {};

  @override
  Future<String> getLocalSongPath(String songId, {String? audioUrl}) async => '/fake/$songId';

  @override
  Future<bool> isSongDownloaded(String songId, {String? audioUrl}) async =>
      existingFiles.contains(songId);

  @override
  Future<void> downloadSong(Song song, {Function(double progress, int total)? onProgress}) async {
    onProgress?.call(1.0, 100);
    existingFiles.add(song.id);
  }

  @override
  Future<void> cancelDownload(String songId) async {}

  @override
  Future<void> deleteSong(String songId, {String? audioUrl}) async {
    throw Exception('disk error');
  }

  @override
  void dispose() {}
}
