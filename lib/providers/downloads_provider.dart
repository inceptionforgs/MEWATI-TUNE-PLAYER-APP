// File: lib/providers/downloads_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/downloads_service.dart';

class DownloadsProvider with ChangeNotifier {
  final DownloadsService _downloadsService;

  // Fixed (Serial 17): DownloadsService is now optionally injectable so
  // tests can pass a fake implementation instead of the real
  // file-system/background_downloader-backed singleton. Default behavior
  // (no argument) is unchanged.
  DownloadsProvider({DownloadsService? downloadsService})
      : _downloadsService = downloadsService ?? DownloadsService();

  final Set<String> _downloadedSongIds = {};
  final Map<String, double> _downloadProgress = {};
  static const String _prefsKey = 'downloaded_song_ids';

  // Full Song data per downloaded id, persisted as JSON — needed so the
  // Downloads tab (File 37) can list every downloaded song regardless of
  // whether it's in SongsProvider's currently-loaded (paginated) page.
  final Map<String, Song> _downloadedSongsData = {};
  static const String _songsPrefsKey = 'downloaded_songs_json';

  final ValueNotifier<Map<String, double>> progressNotifier =
      ValueNotifier<Map<String, double>>({});

  Set<String> get downloadedSongIds => _downloadedSongIds;
  Map<String, double> get downloadProgress => _downloadProgress;
  List<Song> get downloadedSongsList => _downloadedSongsData.values.toList();

  bool isDownloaded(String songId) => _downloadedSongIds.contains(songId);
  bool isDownloading(String songId) => _downloadProgress.containsKey(songId);
  double getProgress(String songId) => _downloadProgress[songId] ?? 0.0;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getStringList(_prefsKey) ?? [];
    _downloadedSongIds
      ..clear()
      ..addAll(cached);

    final cachedSongsJson = prefs.getStringList(_songsPrefsKey) ?? [];
    _downloadedSongsData.clear();
    for (final jsonStr in cachedSongsJson) {
      try {
        final song = Song.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
        _downloadedSongsData[song.id] = song;
      } catch (e) {
        debugPrint('Failed to decode cached downloaded song: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _downloadedSongIds.toList());
  }

  Future<void> _saveSongsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _songsPrefsKey,
      _downloadedSongsData.values.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> checkExistingDownloads(List<Song> allSongs) async {
    if (_downloadedSongIds.isEmpty) {
      await initialize();
    }

    final toCheck = allSongs
        .where((song) => !_downloadedSongIds.contains(song.id))
        .toList();

    final results = await Future.wait(
      toCheck.map((song) async {
        try {
          return await _downloadsService.isSongDownloaded(
            song.id,
            audioUrl: song.audioUrl,
          );
        } catch (e) {
          debugPrint('Download check failed for ${song.id}: $e');
          return false;
        }
      }),
    );

    for (int i = 0; i < toCheck.length; i++) {
      if (results[i]) {
        _downloadedSongIds.add(toCheck[i].id);
        _downloadedSongsData[toCheck[i].id] = toCheck[i];
      }
    }

    await _verifyCachedFiles(allSongs);
    await _saveCache();
    await _saveSongsCache();
    notifyListeners();
  }

  Future<void> _verifyCachedFiles(List<Song> allSongs) async {
    for (final song in allSongs) {
      if (_downloadedSongIds.contains(song.id)) {
        try {
          bool exists = await _downloadsService.isSongDownloaded(
            song.id,
            audioUrl: song.audioUrl,
          );
          if (!exists) {
            _downloadedSongIds.remove(song.id);
            _downloadedSongsData.remove(song.id);
          }
        } catch (e) {
          debugPrint('Cache verification failed for ${song.id}: $e');
        }
      }
    }
    await _saveCache();
    await _saveSongsCache();
  }

  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    _downloadProgress[song.id] = 0.0;
    progressNotifier.value = Map.unmodifiable(_downloadProgress);
    notifyListeners();

    try {
      await _downloadsService.downloadSong(
        song,
        onProgress: (progress, total) {
          _downloadProgress[song.id] = progress;
          // Granular per-song progress lives on progressNotifier, which
          // SongRow (File 21) should consume via ValueListenableBuilder so
          // only that row rebuilds. Deliberately NOT calling notifyListeners()
          // here on every tick — doing so would defeat the point of having
          // progressNotifier at all (whole list would rebuild ~every 100ms
          // during a download, same battery/perf problem as P5-1).
          progressNotifier.value = Map.unmodifiable(_downloadProgress);
        },
      );

      _downloadProgress.remove(song.id);
      progressNotifier.value = Map.unmodifiable(_downloadProgress);
      _downloadedSongIds.add(song.id);
      _downloadedSongsData[song.id] = song;
      await _saveCache();
      await _saveSongsCache();
      notifyListeners();
    } catch (e) {
      _downloadProgress.remove(song.id);
      progressNotifier.value = Map.unmodifiable(_downloadProgress);
      notifyListeners();
      debugPrint("Download Error: $e");
      rethrow; // let the calling screen show a SnackBar (P5-9 error-handling path)
    }
  }

  Future<void> cancelDownload(String songId) async {
    if (!isDownloading(songId)) return;
    await _downloadsService.cancelDownload(songId);
    _downloadProgress.remove(songId);
    progressNotifier.value = Map.unmodifiable(_downloadProgress);
    notifyListeners();
  }

  /// Fixed: `audioUrl` is now REQUIRED, not optional. Previously many call
  /// sites called `removeDownload(songId)` with no audioUrl, and
  /// `getLocalSongPath` silently defaulted to `.m4a` — so an mp3 file's
  /// actual bytes were never deleted from disk, only the id was dropped
  /// from the cache. Making this required forces every call site to pass
  /// the real audioUrl so the correct extension/path is resolved.
  ///
  /// Also fixed: if the underlying file delete fails, the id is now KEPT
  /// in `_downloadedSongIds` / `_downloadedSongsData` (previously it was
  /// dropped unconditionally, causing silent data loss where the app
  /// "forgets" a file it never actually deleted). Returns true on success,
  /// false on failure so the calling screen can show a SnackBar.
  Future<bool> removeDownload(String songId, {required String audioUrl}) async {
    try {
      await _downloadsService.deleteSong(songId, audioUrl: audioUrl);
      _downloadedSongIds.remove(songId);
      _downloadedSongsData.remove(songId);
      await _saveCache();
      await _saveSongsCache();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to remove download for $songId: $e');
      return false;
    }
  }

  @override
  void dispose() {
    progressNotifier.dispose();
    super.dispose();
  }
}
