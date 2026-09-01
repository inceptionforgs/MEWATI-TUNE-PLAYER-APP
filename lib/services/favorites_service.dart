import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/favorite.dart';
import '../models/song.dart';
import 'supabase_service.dart';

class FavoritesService {
  final _supabase = SupabaseService().client;
  static const int _batchSize = 100;

  Future<void> addFavorite(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to add favorites.');
      }
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'song_id': songId,
      });
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

        final songsResponse =
            await _supabase.from('songs').select().inFilter('id', chunk);

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