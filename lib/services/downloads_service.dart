// File: lib/services/downloads_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
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
    // Returns absolute path to the app's documents directory.
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Derive file extension from audio URL.
  String _getExtensionFromUrl(String audioUrl) {
    try {
      final uri = Uri.parse(audioUrl);
      final path = uri.path;
      if (path.contains('.')) {
        final ext = path.split('.').last;
        // Sanitize extension: only allow common audio extensions, else fallback to m4a.
        const allowed = ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'];
        if (allowed.contains(ext.toLowerCase())) {
          return ext.toLowerCase();
        }
      }
    } catch (_) {}
    return 'm4a'; // default fallback
  }

  Future<String> getLocalSongPath(String songId, {String? audioUrl}) async {
    final dirPath = await _getDownloadDirectory();
    final ext = audioUrl != null ? _getExtensionFromUrl(audioUrl) : 'm4a';
    return '$dirPath/MewatiOfflineSongs/song_$songId.$ext';
  }

  Future<bool> isSongDownloaded(String songId, {String? audioUrl}) async {
    final filePath = await getLocalSongPath(songId, audioUrl: audioUrl);
    final file = File(filePath);
    if (!await file.exists()) return false;
    return await file.length() > 0;
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
    // Use audioUrl to determine extension; if not available, fallback to m4a.
    final ext = _getExtensionFromUrl(song.audioUrl);
    final filename = 'song_${song.id}.$ext';
    final taskId = 'song_${song.id}';

    if (await isSongDownloaded(song.id, audioUrl: song.audioUrl)) return;

    final task = DownloadTask(
      taskId: taskId,
      url: song.audioUrl,
      filename: filename,
      directory: 'MewatiOfflineSongs',
      baseDirectory: BaseDirectory.applicationDocuments,
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

      final localPath = await getLocalSongPath(song.id, audioUrl: song.audioUrl);
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Downloaded file not found on disk.');
      }
      if (await file.length() <= 0) {
        await file.delete();
        throw Exception('Downloaded file is empty.');
      }
    } catch (e) {
      _progressCallbacks.remove(taskId);
      _tasks.remove(taskId);
      try {
        await deleteSong(song.id, audioUrl: song.audioUrl);
      } catch (cleanupError) {
        if (kDebugMode) {
          debugPrint('Failed to clean up partial download for ${song.id}: $cleanupError');
        }
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

  Future<void> deleteSong(String songId, {String? audioUrl}) async {
    final filePath = await getLocalSongPath(songId, audioUrl: audioUrl);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void dispose() {
    _progressSubscription?.cancel();
    _progressSubscription = null;
  }
}
