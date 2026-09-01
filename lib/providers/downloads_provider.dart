import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../services/downloads_service.dart';

class DownloadsProvider with ChangeNotifier {
  final DownloadsService _downloadsService = DownloadsService();

  final Set<String> _downloadedSongIds = {};
  final Map<String, double> _downloadProgress = {};
  static const String _prefsKey = 'downloaded_song_ids';

  Set<String> get downloadedSongIds => _downloadedSongIds;
  Map<String, double> get downloadProgress => _downloadProgress;

  bool isDownloaded(String songId) => _downloadedSongIds.contains(songId);
  bool isDownloading(String songId) => _downloadProgress.containsKey(songId);
  double getProgress(String songId) => _downloadProgress[songId] ?? 0.0;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getStringList(_prefsKey) ?? [];
    _downloadedSongIds
      ..clear()
      ..addAll(cached);
    notifyListeners();
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _downloadedSongIds.toList());
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
          return await _downloadsService.isSongDownloaded(song.id);
        } catch (e) {
          debugPrint('Download check failed for ${song.id}: $e');
          return false;
        }
      }),
    );

    for (int i = 0; i < toCheck.length; i++) {
      if (results[i]) {
        _downloadedSongIds.add(toCheck[i].id);
      }
    }

    await _verifyCachedFiles(allSongs);
    await _saveCache();
    notifyListeners();
  }

  Future<void> _verifyCachedFiles(List<Song> allSongs) async {
    for (final song in allSongs) {
      if (_downloadedSongIds.contains(song.id)) {
        try {
          bool exists = await _downloadsService.isSongDownloaded(song.id);
          if (!exists) {
            _downloadedSongIds.remove(song.id);
          }
        } catch (e) {
          debugPrint('Cache verification failed for ${song.id}: $e');
        }
      }
    }
    await _saveCache();
  }

  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    _downloadProgress[song.id] = 0.0;
    notifyListeners();

    try {
      await _downloadsService.downloadSong(
        song,
        onProgress: (progress, total) {
          _downloadProgress[song.id] = progress;
          notifyListeners();
        },
      );

      _downloadProgress.remove(song.id);
      _downloadedSongIds.add(song.id);
      await _saveCache();
      notifyListeners();
    } catch (e) {
      _downloadProgress.remove(song.id);
      notifyListeners();
      debugPrint("Download Error: $e");
    }
  }

  Future<void> cancelDownload(String songId) async {
    if (!isDownloading(songId)) return;
    await _downloadsService.cancelDownload(songId);
    _downloadProgress.remove(songId);
    notifyListeners();
  }

  Future<void> removeDownload(String songId) async {
    await _downloadsService.deleteSong(songId);
    _downloadedSongIds.remove(songId);
    await _saveCache();
    notifyListeners();
  }
}