import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/singer.dart';

String _encodeSongs(List<Map<String, dynamic>> songsJson) => jsonEncode(songsJson);
String _encodeSingers(List<Map<String, dynamic>> singersJson) => jsonEncode(singersJson);
List<dynamic> _decodeList(String jsonString) => jsonDecode(jsonString) as List<dynamic>;

class LocalCacheService {
  static final LocalCacheService _instance = LocalCacheService._internal();
  factory LocalCacheService() => _instance;
  LocalCacheService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> cacheSongs(List<Song> songs) async {
    final prefs = _prefs;
    if (prefs == null) throw Exception('LocalCacheService not initialized');
    final jsonString =
        await compute(_encodeSongs, songs.map((s) => s.toJson()).toList());
    await prefs.setString('cached_songs', jsonString);
  }

  Future<List<Song>?> getCachedSongs() async {
    final prefs = _prefs;
    if (prefs == null) return null;
    final jsonString = prefs.getString('cached_songs');
    if (jsonString == null) return null;
    try {
      final list = await compute(_decodeList, jsonString);
      return list
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheSingers(List<Singer> singers) async {
    final prefs = _prefs;
    if (prefs == null) throw Exception('LocalCacheService not initialized');
    final jsonString = await compute(
        _encodeSingers, singers.map((s) => s.toJson()).toList());
    await prefs.setString('cached_singers', jsonString);
  }

  Future<List<Singer>?> getCachedSingers() async {
    final prefs = _prefs;
    if (prefs == null) return null;
    final jsonString = prefs.getString('cached_singers');
    if (jsonString == null) return null;
    try {
      final list = await compute(_decodeList, jsonString);
      return list
          .map((e) => Singer.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.remove('cached_songs');
    await prefs.remove('cached_singers');
  }
}