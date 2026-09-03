import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:mewati_tune_player/services/downloads_service.dart';

/// Points path_provider's "documents directory" at a real temp folder so
/// DownloadsService's file-path/existence logic can be exercised for real,
/// without needing an actual device.
class _FakePathProviderPlatform extends PathProviderPlatform {
  final String path;
  _FakePathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mewati_downloads_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DownloadsService.getLocalSongPath (extension resolution)', () {
    test('resolves an .mp3 path for an mp3 audioUrl', () async {
      final service = DownloadsService();
      final path = await service.getLocalSongPath(
        'song-1',
        audioUrl: 'https://cdn.example.com/audio/track.mp3',
      );
      expect(path.endsWith('.mp3'), isTrue);
    });

    test('resolves an .m4a path for a non-audio-extension/unknown URL (fallback)', () async {
      final service = DownloadsService();
      final path = await service.getLocalSongPath(
        'song-2',
        audioUrl: 'https://cdn.example.com/audio/track.xyz',
      );
      expect(path.endsWith('.m4a'), isTrue);
    });

    test('resolves an .m4a path when no audioUrl is given', () async {
      final service = DownloadsService();
      final path = await service.getLocalSongPath('song-3');
      expect(path.endsWith('.m4a'), isTrue);
    });

    test('recognizes other allowed extensions like flac and ogg', () async {
      final service = DownloadsService();
      final flacPath = await service.getLocalSongPath(
        'song-4',
        audioUrl: 'https://cdn.example.com/audio/track.flac',
      );
      final oggPath = await service.getLocalSongPath(
        'song-5',
        audioUrl: 'https://cdn.example.com/audio/track.ogg',
      );
      expect(flacPath.endsWith('.flac'), isTrue);
      expect(oggPath.endsWith('.ogg'), isTrue);
    });
  });

  group('DownloadsService.isSongDownloaded / deleteSong', () {
    test('isSongDownloaded is false when no file exists on disk', () async {
      final service = DownloadsService();
      final exists = await service.isSongDownloaded(
        'song-missing',
        audioUrl: 'https://cdn.example.com/audio/track.mp3',
      );
      expect(exists, isFalse);
    });

    test('isSongDownloaded is true only for a non-empty file, and deleteSong removes it', () async {
      final service = DownloadsService();
      final path = await service.getLocalSongPath(
        'song-real',
        audioUrl: 'https://cdn.example.com/audio/track.mp3',
      );
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);

      expect(
        await service.isSongDownloaded('song-real', audioUrl: 'https://cdn.example.com/audio/track.mp3'),
        isTrue,
      );

      await service.deleteSong('song-real', audioUrl: 'https://cdn.example.com/audio/track.mp3');

      expect(await file.exists(), isFalse);
    });
  });
}
