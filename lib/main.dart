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

  // IMPORTANT:
  // DownloadsProvider Supabase par depend nahi karta, isliye ise
  // startup se pehle safely create kiya ja sakta hai.
  final downloadsProvider = DownloadsProvider();

  // ============================================================
  // INITIALIZE ALL CORE SERVICES FIRST
  //
  // IMPORTANT FIX:
  //
  // AuthProvider ko Supabase initialize hone se PEHLE create nahi
  // karna chahiye.
  //
  // AuthProvider constructor immediately authStateChanges listen
  // karta hai, jo SupabaseService().client access karta hai.
  //
  // Isliye initialization order:
  //
  // Supabase initialize
  //        ↓
  // AuthProvider create
  //        ↓
  // runApp
  // ============================================================

  await _initializeApp(downloadsProvider);

  // Supabase initialization attempt complete hone ke BAAD hi
  // AuthProvider create karo.
  final authProvider = AuthProvider();

  runApp(
    MewatiTunePlayerApp(
      authProvider: authProvider,
      downloadsProvider: downloadsProvider,
    ),
  );
}

Future<void> _initializeApp(
  DownloadsProvider downloadsProvider,
) async {
  try {
    // ============================================================
    // OPTIONAL ENVIRONMENT FILE
    // ============================================================

    // Load environment variables (optional).
    //
    // Supabase/Sentry configuration dotenv se directly depend nahi
    // karti, lekin optional .env doosre non-critical parts ke liye
    // available reh sakti hai.
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env optional hai.
      // Missing hone par app startup block nahi hoga.
      debugPrint('Optional .env not loaded: $e');
    }

    // ============================================================
    // JUST AUDIO BACKGROUND
    // ============================================================

    // Background audio support initialize karo.
    //
    // Timeout intentionally use kiya gaya hai taaki koi stuck
    // platform-channel call native splash screen ko permanently
    // hold na kare.
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId:
            'com.mewatitune.player.channel.audio',
        androidNotificationChannelName:
            'Mewati Tune Player Playback',
        androidNotificationOngoing: true,
      ).timeout(
        const Duration(seconds: 8),
      );
    } catch (e) {
      debugPrint(
        'JustAudioBackground.init failed/timed out: $e',
      );

      // Non-fatal startup failure.
      // App boot continue karega.
    }

    // ============================================================
    // SUPABASE
    // ============================================================

    // IMPORTANT:
    //
    // AuthProvider create hone se pehle Supabase initialization
    // yahin complete hota hai.
    try {
      await SupabaseService().initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Supabase initialization timed out.',
          );
        },
      );

      DebugLogService().info(
        'Supabase initialized successfully',
      );
    } catch (e) {
      debugPrint(
        'Supabase init failed/timed out: $e',
      );

      DebugLogService().error(
        'Supabase initialization failed: $e',
      );

      // IMPORTANT:
      //
      // Is failure ke baad app run karne ki koshish karne par
      // AuthProvider Supabase client access karega.
      //
      // Isliye configuration/startup problem ko clearly surface
      // karne ke liye exception rethrow kiya ja raha hai.
      //
      // Agar Supabase initialize nahi ho sakta, AuthProvider ko
      // create karna safe nahi hai.
      rethrow;
    }

    // ============================================================
    // LOCAL CACHE
    // ============================================================

    try {
      await LocalCacheService()
          .initialize()
          .timeout(
            const Duration(seconds: 5),
          );

      DebugLogService().info(
        'Local cache initialized successfully',
      );
    } catch (e) {
      debugPrint(
        'LocalCacheService.initialize failed/timed out: $e',
      );

      DebugLogService().error(
        'Local cache initialization failed: $e',
      );

      // Cache failure fatal nahi hai.
      // App network data ke saath continue kar sakta hai.
    }

    // ============================================================
    // DOWNLOADS PROVIDER
    // ============================================================

    try {
      await downloadsProvider.initialize().timeout(
        const Duration(seconds: 5),
      );

      DebugLogService().info(
        'DownloadsProvider initialized successfully',
      );
    } catch (e) {
      debugPrint(
        'DownloadsProvider.initialize failed/timed out: $e',
      );

      DebugLogService().error(
        'DownloadsProvider initialization failed: $e',
      );

      // Download cache/load failure startup ko block nahi karega.
    }

    // ============================================================
    // SENTRY
    // ============================================================

    // Sentry sirf tab initialize hoga jab DSN provided ho.
    if (Environment.sentryDsn.isNotEmpty) {
      try {
        await SentryFlutter.init(
          (options) {
            options.dsn = Environment.sentryDsn;
            options.tracesSampleRate =
                Environment.sentryTracesSampleRate;
          },
        ).timeout(
          const Duration(seconds: 5),
        );

        DebugLogService().info(
          'Sentry initialized successfully',
        );
      } catch (e) {
        debugPrint(
          'SentryFlutter.init failed/timed out: $e',
        );

        DebugLogService().error(
          'Sentry initialization failed: $e',
        );

        // Sentry failure app startup ko block nahi karega.
      }
    }

    // ============================================================
    // STARTUP COMPLETE
    // ============================================================

    DebugLogService().info(
      'App initialized successfully',
    );
  } catch (e) {
    DebugLogService().error(
      'App initialization failed: $e',
    );

    // Supabase initialization fatal hai because AuthProvider
    // Supabase client par depend karta hai.
    rethrow;
  }
}