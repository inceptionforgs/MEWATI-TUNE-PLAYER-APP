import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:background_downloader/background_downloader.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/downloads_provider.dart';
import 'services/debug_log_service.dart';
import 'services/local_cache_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {}

    // Initialize background_downloader — REQUIRED for download functionality
    await FileDownloader().initialize();

    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.mewatitune.player.channel.audio',
      androidNotificationChannelName: 'Mewati Tune Player Playback',
      androidNotificationOngoing: true,
    );

    await SupabaseService().initialize();
    await LocalCacheService().initialize();

    final authProvider = AuthProvider();
    await authProvider.loadCurrentUser();

    final downloadsProvider = DownloadsProvider();
    await downloadsProvider.initialize();

    DebugLogService().info('App started');
    DebugLogService().info(
        'Auth status: ${authProvider.isLoggedIn ? "logged in" : "not logged in"}');

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

    Connectivity().onConnectivityChanged.listen((_) {});

    runApp(
      MewatiTunePlayerApp(
        authProvider: authProvider,
        downloadsProvider: downloadsProvider,
      ),
    );
  } catch (e) {
    DebugLogService().error('App failed to start: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to start app:\n\n${e.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}