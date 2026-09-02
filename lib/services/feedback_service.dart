import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FeedbackService {
  // Getter, not a field initializer — same fix pattern as File 6, so this
  // never throws "Supabase client not initialized" if constructed early.
  SupabaseClient get _supabase => SupabaseService().client;

  /// Submits a feedback/bug/song-suggestion row.
  /// [songId] is nullable — only set when opened from a song's context menu.
  Future<void> submitFeedback({
    required String message,
    String? category, // 'bug' | 'song_suggestion' | 'other'
    String? songId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You need an active session to submit feedback.');
    }

    try {
      await _supabase.from('feedback').insert({
        'user_id': userId,
        'category': category,
        'message': message,
        'song_id': songId,
      });
    } catch (e) {
      throw Exception('Failed to submit feedback: ${e.toString()}');
    }
  }
}
