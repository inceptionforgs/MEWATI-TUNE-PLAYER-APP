import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class AuthService {
  SupabaseClient get _supabase => SupabaseService().client;

  Future<void> signInAnonymously() async {
    try {
      final response = await _supabase.auth.signInAnonymously();
      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('Anonymous sign-in failed: no user returned.');
      }
      await _ensureProfileExists(userId);
    } catch (e) {
      throw Exception('Anonymous sign-in failed: ${e.toString()}');
    }
  }

  /// Ensures a profile row exists for [userId].
  /// Retries once on failure and surfaces the error instead of swallowing it,
  /// so callers (AuthProvider) can decide whether to retry again later.
  Future<void> _ensureProfileExists(String userId, {int attempt = 0}) async {
    try {
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('profiles').insert({
          'id': userId,
          'subscription_status': 'free',
          'subscription_expiry': null,
        });
      }
    } catch (e) {
      debugPrint('AuthService: profile creation failed (attempt $attempt): $e');
      if (attempt < 1) {
        // One retry — transient network/RLS hiccups on first launch are common.
        await _ensureProfileExists(userId, attempt: attempt + 1);
        return;
      }
      // Surface the error after retrying instead of silently continuing,
      // so AuthProvider can reflect the failure and retry later if needed.
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Public entry point so AuthProvider can retry profile creation
  /// after a failed attempt (e.g. once connectivity is restored).
  Future<void> retryProfileCreation() async {
    final userId = getCurrentUser()?.id;
    if (userId == null) return;
    await _ensureProfileExists(userId);
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<Profile?> fetchProfile() async {
    try {
      final user = getCurrentUser();
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load profile: ${e.toString()}');
    }
  }
}
