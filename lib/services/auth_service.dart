import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'supabase_service.dart';

class AuthService {
  final _supabase = SupabaseService().client;

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

  Future<void> _ensureProfileExists(String userId) async {
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
      // Non-fatal: profile creation failure should not block app usage.
    }
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