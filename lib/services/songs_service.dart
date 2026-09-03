import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/like_pattern_escaper.dart';
import '../models/song.dart';
import 'supabase_service.dart';

class SongsService {
  SupabaseClient get _supabase => SupabaseService().client;

  // Fixed (Serial 17): row validation/skip logic moved to
  // Song.mapValidRows so it can be unit tested directly. Behavior
  // unchanged — a row with a missing id or empty/invalid audioUrl is
  // still skipped, never thrown.
  List<Song> _mapSongs(List<dynamic> response) => Song.mapValidRows(response);

  // Fixed (Serial 17): now delegates to the shared escapeLikePattern
  // utility (lib/core/utils/like_pattern_escaper.dart) instead of a
  // private duplicate that could never be unit tested on its own.
  // Behavior unchanged.

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

      final safeQuery = escapeLikePattern(query.trim());

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
