// File: lib/services/favorites_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song.dart';
import 'supabase_service.dart';

class FavoritesService {
  SupabaseClient get _supabase => SupabaseService().client;
  static const int _batchSize = 100;

  Future<void> addFavorite(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to add favorites.');
      }
      // Upsert with ignoreDuplicates so a double-tap / race that hits the
      // (user_id, song_id) unique constraint doesn't throw.
      await _supabase.from('favorites').upsert(
        {
          'user_id': userId,
          'song_id': songId,
        },
        onConflict: 'user_id,song_id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      throw Exception('Failed to add favorite: ${e.toString()}');
    }
  }

  Future<void> removeFavorite(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to remove favorites.');
      }
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('song_id', songId);
    } catch (e) {
      throw Exception('Failed to remove favorite: ${e.toString()}');
    }
  }

  Future<bool> isFavorite(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', userId)
          .eq('song_id', songId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Song>> fetchFavoriteSongs() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final favoriteRows = await _supabase
          .from('favorites')
          .select('song_id')
          .eq('user_id', userId);

      final List<String> songIds = favoriteRows
          .map((row) => row['song_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (songIds.isEmpty) return [];

      final List<Song> songs = [];
      for (int i = 0; i < songIds.length; i += _batchSize) {
        final chunk = songIds.sublist(
          i,
          (i + _batchSize > songIds.length) ? songIds.length : i + _batchSize,
        );

        // Include singers(name) — without it, favorited songs showed
        // "Unknown Artist" because singer_name never came back on this join.
        final songsResponse = await _supabase
            .from('songs')
            .select('*, singers(name)')
            .inFilter('id', chunk);

        songs.addAll(
          (songsResponse as List<dynamic>)
              .map((json) => Song.fromJson(json as Map<String, dynamic>)),
        );
      }

      return songs;
    } catch (e) {
      throw Exception('Failed to load favorite songs: ${e.toString()}');
    }
  }
}
