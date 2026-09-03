import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import 'supabase_service.dart';

class SongsService {
  SupabaseClient get _supabase => SupabaseService().client;

  // Helper to map response rows to Song objects, skipping any invalid row.
  // A row is skipped (not thrown) if it has no id, or if audioUrl is
  // empty/invalid — one bad row must never break the whole list.
  List<Song> _mapSongs(List<dynamic> response) {
    final songs = <Song>[];
    for (final item in response) {
      try {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        final audioUrl = map['audio_url'] as String? ?? '';
        if (id.isEmpty || audioUrl.trim().isEmpty) {
          debugPrint('SongsService: skipping row with missing id/audioUrl: $map');
          continue;
        }
        songs.add(Song.fromJson(map));
      } catch (e) {
        debugPrint('SongsService: skipping invalid song row: $e');
      }
    }
    return songs;
  }

  String _escapeLikePattern(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
  }

  Future<List<Song>> fetchSongsPage({required int offset, required int limit}) async {
    try {
      final response = await _supabase
          .from('songs')
          .select('*, singers(name)')
          .order('title', ascending: true)
          .range(offset, offset + limit - 1);

      return _mapSongs(response as List<dynamic>);
    } catch (e) {
      throw Exception('Failed to load songs page: ${e.toString()}');
    }
  }

  Future<List<Song>> fetchTrendingPage({required int offset, required int limit}) async {
    try {
      final response = await _supabase
          .from('songs')
          .select('*, singers(name)')
          .order('play_count', ascending: false)
          .range(offset, offset + limit - 1);

      return _mapSongs(response as List<dynamic>);
    } catch (e) {
      throw Exception('Failed to load trending songs: ${e.toString()}');
    }
  }

  Future<Song?> fetchSongById(String songId) async {
    try {
      final response = await _supabase
          .from('songs')
          .select('*, singers(name)')
          .eq('id', songId)
          .maybeSingle();

      if (response == null) return null;
      return Song.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load song: ${e.toString()}');
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final safeQuery = _escapeLikePattern(query.trim());

      final response = await _supabase
          .from('songs')
          .select('*, singers(name)')
          .ilike('title', '%$safeQuery%')
          .limit(20);

      return _mapSongs(response as List<dynamic>);
    } catch (e) {
      throw Exception('Search failed for songs: ${e.toString()}');
    }
  }

  Future<List<Song>> fetchSongsBySinger(String singerId) async {
    try {
      final response = await _supabase
          .from('songs')
          .select('*, singers(name)')
          .eq('singer_id', singerId)
          .order('title', ascending: true);

      return _mapSongs(response as List<dynamic>);
    } catch (e) {
      throw Exception('Failed to load songs for singer: ${e.toString()}');
    }
  }

  Future<void> incrementPlayCount(String songId) async {
    try {
      await _supabase.rpc(
        'increment_play_count',
        params: {'p_song_id': songId},
      );
    } catch (e) {
      // Non-critical operation — silently ignore errors.
    }
  }
}
