// File: lib/main.dart

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

  final downloadsProvider = DownloadsProvider();

  try {
    await _initializeApp(downloadsProvider);
  } catch (e) {
    // FIXED: Supabase init failure (no internet, bad config, timeout)
    // used to crash before runApp() was ever called — blank screen,
    // no retry. Now we boot a minimal error/retry app instead of
    // letting the exception escape main() uncaught.
    runApp(_StartupErrorApp(error: e.toString()));
    return;
  }

  final authProvider = AuthProvider();

  runApp(
    MewatiTunePlayerApp(
      authProvider: authProvider,
      downloadsProvider: downloadsProvider,
    ),
  );
}

class _StartupErrorApp extends StatelessWidget {
  final String error;

  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white70, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not connect. Please check your internet and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeApp(
  DownloadsProvider downloadsProvider,
) async {
  try {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Optional .env not loaded: $e');
    }

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
    }

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

      rethrow;
    }

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
    }

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
    }

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
      }
    }

    DebugLogService().info(
      'App initialized successfully',
    );
  } catch (e) {
    DebugLogService().error(
      'App initialization failed: $e',
    );

    rethrow;
  }
}
