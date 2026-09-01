import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class LikeService {
  final _supabase = SupabaseService().client;

  Future<bool> isLiked(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('likes')
          .select('song_id')
          .eq('user_id', userId)
          .eq('song_id', songId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<int> getLikeCount(String songId) async {
    try {
      final response = await _supabase
          .from('songs')
          .select('like_count')
          .eq('id', songId)
          .maybeSingle();

      return (response != null) ? (response['like_count'] as int? ?? 0) : 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> addLike(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to like songs.');
      }
      await _supabase.from('likes').insert({
        'user_id': userId,
        'song_id': songId,
      });
      await _supabase.rpc(
        'increment_like_count',
        params: {'song_id_input': songId},
      );
    } catch (e) {
      throw Exception('Failed to add like: ${e.toString()}');
    }
  }

  Future<void> removeLike(String songId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be logged in to unlike songs.');
      }
      await _supabase
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('song_id', songId);
      await _supabase.rpc(
        'decrement_like_count',
        params: {'song_id_input': songId},
      );
    } catch (e) {
      throw Exception('Failed to remove like: ${e.toString()}');
    }
  }

  Future<bool> toggleLike(String songId) async {
    final liked = await isLiked(songId);
    if (liked) {
      await removeLike(songId);
      return false;
    } else {
      await addLike(songId);
      return true;
    }
  }
}