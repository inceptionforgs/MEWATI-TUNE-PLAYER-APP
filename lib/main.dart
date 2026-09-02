import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/downloads_provider.dart';
import 'services/debug_log_service.dart';
import 'services/local_cache_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  final downloadsProvider = DownloadsProvider();

  // Fully initialize Supabase, audio, cache, auth session, and downloads
  // BEFORE the UI is shown. The app must never open in a half-initialized
  // state (this used to be a fire-and-forget call, which is why favorites/
  // auth state used to load empty on first frame).
  await _initializeApp(authProvider, downloadsProvider);

  runApp(
    MewatiTunePlayerApp(
      authProvider: authProvider,
      downloadsProvider: downloadsProvider,
    ),
  );
}

Future<void> _initializeApp(
  AuthProvider authProvider,
  DownloadsProvider downloadsProvider,
) async {
  try {
    // Load environment variables (optional).
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // Initialize just_audio background support (needed for playback).
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.mewatitune.player.channel.audio',
      androidNotificationChannelName: 'Mewati Tune Player Playback',
      androidNotificationOngoing: true,
    );

    // Initialize Supabase.
    await SupabaseService().initialize();

    // Initialize local cache (SharedPreferences).
    await LocalCacheService().initialize();

    // Load user session (will trigger anonymous sign-in if needed).
    await authProvider.loadCurrentUser();

    // Initialize downloads provider (reads cached downloaded IDs).
    await downloadsProvider.initialize();

    // Initialize Sentry only if DSN is provided.
    final sentryDsn =
        dotenv.isInitialized ? (dotenv.env['SENTRY_DSN'] ?? '') : '';
    if (sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 1.0;
        },
      );
    }

    // Request notification permission on Android 13+ (needed for media playback).
    await _requestNotificationPermission();

    DebugLogService().info('App initialized successfully');
  } catch (e) {
    DebugLogService().error('App initialization failed: $e');
    // The app continues to run; splash screen will show appropriate UI.
  }
}

Future<void> _requestNotificationPermission() async {
  try {
    // On Android 13+ (API 33+), we need to request POST_NOTIFICATIONS.
    // On older versions, permission is granted by default.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  } catch (e) {
    DebugLogService().warning('Notification permission request failed: $e');
  }
}
