import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class LikeService {
  SupabaseClient get _supabase => SupabaseService().client;

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

  /// Toggles the current user's like on [songId] via the single
  /// `toggle_like` RPC (SECURITY DEFINER, requires auth.uid()).
  /// The RPC does the likes insert/delete AND the songs.like_count
  /// update in one transaction, so client and server can never desync.
  ///
  /// Returns the new like_count for the song after the toggle.
  /// Replaces the old separate insert + increment_like_count /
  /// delete + decrement_like_count calls entirely — those RPCs must
  /// no longer be called directly from the client.
  Future<int> toggleLike(String songId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in to like songs.');
    }
    try {
      final result = await _supabase.rpc(
        'toggle_like',
        params: {'song_id_input': songId},
      );
      if (result is int) return result;
      if (result is num) return result.toInt();
      return 0;
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
    }
  }
}
