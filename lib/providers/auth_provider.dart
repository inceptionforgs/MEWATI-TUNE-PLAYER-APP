// FILE: lib/providers/auth_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/error_handler.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authStateSub;

  /// Called when a session becomes ready (sign-in completed / restored)
  /// so dependent providers (favorites, likes) can reload their data
  /// instead of staying stuck empty from an earlier failed load.
  VoidCallback? onSessionReady;

  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fix (File 16): isLoggedIn must reflect actual auth session state,
  // not whether the profile row happened to load successfully.
  bool get isLoggedIn => _authService.getCurrentUser() != null;

  // Fixed (Serial 17): AuthService is now optionally injectable so tests
  // can pass a fake implementation instead of the real Supabase-backed
  // singleton. Default behavior (no argument) is unchanged.
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService() {
    _authStateSub = _authService.authStateChanges.listen((state) {
      final signedIn = state.session != null;
      if (signedIn) {
        onSessionReady?.call();
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Profile? profile = await _authService.fetchProfile();

      if (_authService.getCurrentUser() == null) {
        await _authService.signInAnonymously();
        profile = await _authService.fetchProfile();
      }

      // Retry profile creation/fetch if it failed the first time
      // (pairs with File 6's fix to stop swallowing the insert error).
      if (profile == null && _authService.getCurrentUser() != null) {
        for (var attempt = 0; attempt < 2 && profile == null; attempt++) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          try {
            await _authService.signInAnonymously();
          } catch (e) {
            debugPrint('Retry signInAnonymously attempt $attempt failed: $e');
          }
          profile = await _authService.fetchProfile();
        }
      }

      _profile = profile;
      onSessionReady?.call();
    } catch (e) {
      _profile = null;
      _errorMessage = 'Failed to start session: ${ErrorHandler.getMessage(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signOut();
      _profile = null;
    } catch (e) {
      _errorMessage = ErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    super.dispose();
  }
}
