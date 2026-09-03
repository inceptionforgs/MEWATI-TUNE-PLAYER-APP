// FILE: lib/main.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'config/environment.dart';
import 'providers/auth_provider.dart';
import 'providers/downloads_provider.dart';
import 'services/debug_log_service.dart';
import 'services/local_cache_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  final downloadsProvider = DownloadsProvider();

  // Fully await core initialization BEFORE runApp — the native launch
  // screen (android/app/src/main/res/drawable/launch_background.xml) stays
  // on screen the whole time, so the app is never shown half-initialized.
  //
  // Auth restoration itself is intentionally NOT awaited here: it's owned
  // by SplashScreen (lib/screens/splash/splash_screen.dart, File 15), which
  // awaits authProvider.loadCurrentUser() with its own timeout and
  // Retry/Continue Offline UI. Awaiting it a second time here would just
  // race/duplicate that network call for no benefit.
  await _initializeApp(downloadsProvider);

  runApp(
    MewatiTunePlayerApp(
      authProvider: authProvider,
      downloadsProvider: downloadsProvider,
    ),
  );
}

Future<void> _initializeApp(DownloadsProvider downloadsProvider) async {
  try {
    // Load environment variables (optional). Supabase/Sentry config no
    // longer read from dotenv (see File 14) — this stays only in case
    // other, non-critical parts of the app still want an optional .env.
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // Optional file — app must keep booting without it. Logged only.
      debugPrint('Optional .env not loaded: $e');
    }

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

    // Initialize downloads provider (reads cached downloaded IDs).
    await downloadsProvider.initialize();

    // Initialize Sentry only if a DSN was injected via --dart-define
    // (Environment.sentryDsn — same no-hardcoded-fallback pattern as
    // SupabaseConfig, see File 14).
    if (Environment.sentryDsn.isNotEmpty) {
      await SentryFlutter.init(
        (options) {
          options.dsn = Environment.sentryDsn;
          options.tracesSampleRate = Environment.sentryTracesSampleRate;
        },
      );
    }

    // Notification permission (Android 13+ POST_NOTIFICATIONS) is no longer
    // requested here at bootstrap. It's now requested the first time the
    // user actually starts playback — see PlayerService.setPlaylist, right
    // before the first play() call — guarded so it only ever asks once.

    DebugLogService().info('App initialized successfully');
  } catch (e) {
    DebugLogService().error('App initialization failed: $e');
    // Deliberately not rethrown: the app still runs, and SplashScreen's own
    // auth-restore attempt will surface a proper Retry/Continue Offline UI
    // if Supabase/network is actually unreachable. Playback/API/DNS errors
    // themselves are handled at the point each call happens (player, auth,
    // search, etc.), not here — this is just startup bootstrapping.
  }
}
