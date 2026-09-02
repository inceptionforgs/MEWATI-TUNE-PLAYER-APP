import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class DownloadsService {
  static final DownloadsService _instance = DownloadsService._internal();
  factory DownloadsService() => _instance;
  DownloadsService._internal() {
    _init();
  }

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, Function(double progress, int total)?> _progressCallbacks = {};
  StreamSubscription<TaskUpdate>? _progressSubscription;

  Future<String> _getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/MewatiOfflineSongs';
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  /// Get local path for a song. Extension is optional; default is 'mp3'.
  Future<String> getLocalSongPath(String songId, {String? extension}) async {
    final dirPath = await _getDownloadDirectory();
    final ext = extension ?? 'mp3';
    return '$dirPath/song_$songId.$ext';
  }

  Future<bool> isSongDownloaded(String songId) async {
    // Try with .mp3 first, fallback to .m4a for backward compatibility
    for (final ext in ['mp3', 'm4a']) {
      final filePath = await getLocalSongPath(songId, extension: ext);
      final file = File(filePath);
      if (await file.exists() && await file.length() > 0) {
        return true;
      }
    }
    return false;
  }

  void _init() {
    _progressSubscription = FileDownloader().updates.listen((event) {
      if (event is TaskProgressUpdate) {
        final callback = _progressCallbacks[event.task.taskId];
        if (callback != null) {
          callback(event.progress, event.expectedFileSize ?? 0);
        }
      }
    });
  }

  Future<void> downloadSong(
    Song song, {
    Function(double progress, int total)? onProgress,
  }) async {
    // Check if already downloaded (any extension)
    if (await isSongDownloaded(song.id)) return;

    final dirPath = await _getDownloadDirectory();
    final taskId = 'song_${song.id}';
    
    // 🔥 Dynamic extension from URL
    final extension = song.audioUrl.split('.').last.split('?').first; // 'mp3'
    final filename = 'song_${song.id}.$extension';

    final task = DownloadTask(
      taskId: taskId,
      url: song.audioUrl,
      filename: filename,
      directory: dirPath,
      updates: Updates.statusAndProgress,
      allowPause: true,
    );

    if (onProgress != null) {
      _progressCallbacks[taskId] = onProgress;
    }
    _tasks[taskId] = task;

    try {
      final result = await FileDownloader().download(task);

      _progressCallbacks.remove(taskId);
      _tasks.remove(taskId);

      if (result.status != TaskStatus.complete) {
        throw Exception('Download did not complete: ${result.status}');
      }

      // 🔥 IMPORTANT: Use the actual file path from result
      final localPath = result.filePath;
      if (localPath == null) {
        throw Exception('Download result has no file path.');
      }

      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found on disk at $localPath');
      }
      if (await file.length() <= 0) {
        await file.delete();
        throw Exception('Downloaded file is empty.');
      }

      // Optional: You can store the extension mapping if needed later
      // e.g., SharedPreferences to remember extension per song
    } catch (e) {
      _progressCallbacks.remove(taskId);
      _tasks.remove(taskId);
      try {
        await deleteSong(song.id);
      } catch (cleanupError) {
        print('Failed to clean up partial download for ${song.id}: $cleanupError');
      }
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  Future<void> cancelDownload(String songId) async {
    final taskId = 'song_$songId';
    if (_tasks.containsKey(taskId)) {
      await FileDownloader().cancelTaskWithId(taskId);
      _tasks.remove(taskId);
      _progressCallbacks.remove(taskId);
    }
  }

  Future<void> deleteSong(String songId) async {
    // Try both extensions while deleting
    for (final ext in ['mp3', 'm4a']) {
      final filePath = await getLocalSongPath(songId, extension: ext);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
  }
}