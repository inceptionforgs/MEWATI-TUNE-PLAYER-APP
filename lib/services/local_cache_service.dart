// File: lib/services/local_cache_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../models/singer.dart';

String _encodeSongs(List<Map<String, dynamic>> songsJson) => jsonEncode(songsJson);
String _encodeSingers(List<Map<String, dynamic>> singersJson) => jsonEncode(singersJson);
List<dynamic> _decodeList(String jsonString) => jsonDecode(jsonString) as List<dynamic>;

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  Directory? _cacheDir;

  static const String _songsFileName = 'cached_songs.json';
  static const String _singersFileName = 'cached_singers.json';

  // Fixed (P5-5): the catalog used to be dumped into SharedPreferences as
  // one big string (~1-2MB), which risks a crash on iOS as it grows.
  // SharedPreferences is now reserved for small flags/ids elsewhere in the
  // app (e.g. DownloadsProvider's id list) — bulk catalog data lives in
  // plain JSON files under the app's documents directory instead.
  Future<void> initialize() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${docsDir.path}/local_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDir = cacheDir;
  }

  Future<void> cacheSongs(List<Song> songs) async {
    final dir = _cacheDir;
    if (dir == null) throw Exception('LocalCacheService not initialized');
    final jsonString =
        await compute(_encodeSongs, songs.map((s) => s.toJson()).toList());
    final file = File('${dir.path}/$_songsFileName');
    await file.writeAsString(jsonString);
  }

  Future<List<Song>?> getCachedSongs() async {
    final dir = _cacheDir;
    if (dir == null) return null;
    final file = File('${dir.path}/$_songsFileName');
    if (!await file.exists()) return null;
    try {
      final jsonString = await file.readAsString();
      final list = await compute(_decodeList, jsonString);
      return list
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheSingers(List<Singer> singers) async {
    final dir = _cacheDir;
    if (dir == null) throw Exception('LocalCacheService not initialized');
    final jsonString = await compute(
        _encodeSingers, singers.map((s) => s.toJson()).toList());
    final file = File('${dir.path}/$_singersFileName');
    await file.writeAsString(jsonString);
  }

  Future<List<Singer>?> getCachedSingers() async {
    final dir = _cacheDir;
    if (dir == null) return null;
    final file = File('${dir.path}/$_singersFileName');
    if (!await file.exists()) return null;
    try {
      final jsonString = await file.readAsString();
      final list = await compute(_decodeList, jsonString);
      return list
          .map((e) => Singer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final dir = _cacheDir;
    if (dir == null) return;
    final songsFile = File('${dir.path}/$_songsFileName');
    final singersFile = File('${dir.path}/$_singersFileName');
    if (await songsFile.exists()) await songsFile.delete();
    if (await singersFile.exists()) await singersFile.delete();
  }
}
