import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/widgets/debug_panel.dart';
import 'providers/auth_provider.dart';
import 'providers/player_provider.dart';
import 'providers/songs_provider.dart';
import 'providers/singers_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/downloads_provider.dart';
import 'providers/likes_provider.dart';
import 'providers/sleep_timer_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';

class MewatiTunePlayerApp extends StatelessWidget {
  final AuthProvider? authProvider;
  final DownloadsProvider? downloadsProvider;

  const MewatiTunePlayerApp({
    Key? key,
    this.authProvider,
    this.downloadsProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<DownloadsProvider>(
          create: (_) => downloadsProvider ?? DownloadsProvider(),
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => SongsProvider()),
        ChangeNotifierProvider(create: (_) => SingersProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => LikesProvider()),
        ChangeNotifierProvider(create: (_) => SleepTimerProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Mewati Tune Player',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.fromAppTheme(themeProvider.theme),
            onGenerateRoute: AppRouter.generateRoute,
            initialRoute: '/',
            builder: (context, child) {
              return Stack(
                children: [
                  if (child != null) child,
                  const DebugPanel(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}