import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mewati_tune_player/models/profile.dart';
import 'package:mewati_tune_player/providers/auth_provider.dart';
import 'package:mewati_tune_player/services/auth_service.dart';

/// Fake AuthService used only in tests.
///
/// Implements (not extends) AuthService: AuthService uses a private
/// `_supabase` getter internally, and this fake never needs a real
/// Supabase client since every public method AuthProvider calls is
/// overridden here with in-memory behavior.
class FakeAuthService implements AuthService {
  User? _currentUser;
  Profile? profileToReturn;
  Object? signInError;
  Object? fetchProfileError;
  int signInAnonymouslyCallCount = 0;

  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  void setSignedIn(bool signedIn) {
    _currentUser = signedIn
        ? User(
            id: 'fake-user-id',
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          )
        : null;
  }

  @override
  User? getCurrentUser() => _currentUser;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInAnonymously() async {
    signInAnonymouslyCallCount++;
    if (signInError != null) {
      final err = signInError!;
      throw err;
    }
    setSignedIn(true);
  }

  @override
  Future<Profile?> fetchProfile() async {
    if (fetchProfileError != null) {
      final err = fetchProfileError!;
      throw err;
    }
    if (_currentUser == null) return null;
    return profileToReturn;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<void> retryProfileCreation() async {
    // Not exercised by AuthProvider directly; no-op for tests.
  }

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  group('AuthProvider.loadCurrentUser', () {
    test('signs in anonymously and loads the profile when there is no existing session', () async {
      final fake = FakeAuthService()
        ..profileToReturn = Profile(id: 'fake-user-id', subscriptionStatus: 'free');
      final provider = AuthProvider(authService: fake);

      await provider.loadCurrentUser();

      expect(fake.signInAnonymouslyCallCount, 1);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.profile?.id, 'fake-user-id');
      expect(provider.errorMessage, isNull);

      fake.dispose();
    });

    test('restores an existing session without signing in again', () async {
      final fake = FakeAuthService()
        ..setSignedIn(true)
        ..profileToReturn = Profile(id: 'fake-user-id', subscriptionStatus: 'premium');
      final provider = AuthProvider(authService: fake);

      await provider.loadCurrentUser();

      expect(fake.signInAnonymouslyCallCount, 0);
      expect(provider.isLoggedIn, isTrue);
      expect(provider.profile?.subscriptionStatus, 'premium');

      fake.dispose();
    });

    test('surfaces an error and leaves profile null when Supabase is unreachable', () async {
      final fake = FakeAuthService()
        ..signInError = Exception('SocketException: Failed host lookup');
      final provider = AuthProvider(authService: fake);

      await provider.loadCurrentUser();

      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);

      fake.dispose();
    });

    test('clearError clears a previously set error message', () async {
      final fake = FakeAuthService()..signInError = Exception('network down');
      final provider = AuthProvider(authService: fake);
      await provider.loadCurrentUser();
      expect(provider.errorMessage, isNotNull);

      provider.clearError();

      expect(provider.errorMessage, isNull);
      fake.dispose();
    });
  });

  group('AuthProvider.signOut', () {
    test('clears the profile on success', () async {
      final fake = FakeAuthService()
        ..setSignedIn(true)
        ..profileToReturn = Profile(id: 'fake-user-id', subscriptionStatus: 'free');
      final provider = AuthProvider(authService: fake);
      await provider.loadCurrentUser();
      expect(provider.profile, isNotNull);

      await provider.signOut();

      expect(provider.profile, isNull);
      expect(provider.errorMessage, isNull);
      fake.dispose();
    });
  });
}
