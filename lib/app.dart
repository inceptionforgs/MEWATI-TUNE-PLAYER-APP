import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_dimensions.dart';
import 'core/widgets/debug_panel.dart';
import 'core/widgets/mini_player_bar.dart';
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

class MewatiTunePlayerApp extends StatefulWidget {
  final AuthProvider? authProvider;
  final DownloadsProvider? downloadsProvider;

  const MewatiTunePlayerApp({
    Key? key,
    this.authProvider,
    this.downloadsProvider,
  }) : super(key: key);

  @override
  State<MewatiTunePlayerApp> createState() => _MewatiTunePlayerAppState();
}

class _MewatiTunePlayerAppState extends State<MewatiTunePlayerApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String?> _currentRouteName = ValueNotifier<String?>(null);
  late final RouteObserver<PageRoute> _routeObserver;

  @override
  void initState() {
    super.initState();
    _routeObserver = RouteObserver<PageRoute>();
    _routeObserver.subscribe(this, (Route<dynamic>? route) {
      if (route is PageRoute) {
        _currentRouteName.value = route.settings.name;
      }
    });
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _currentRouteName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => widget.authProvider ?? AuthProvider(),
        ),
        ChangeNotifierProvider<DownloadsProvider>(
          create: (_) => widget.downloadsProvider ?? DownloadsProvider(),
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
            navigatorKey: _navigatorKey,
            navigatorObservers: [_routeObserver],
            initialRoute: '/',
            builder: (context, child) {
              return ValueListenableBuilder<String?>(
                valueListenable: _currentRouteName,
                builder: (context, routeName, _) {
                  final playerProvider = context.read<PlayerProvider>();
                  final hasSong = playerProvider.hasSong;
                  final isNowPlaying = routeName == '/now-playing';
                  final isSplash = routeName == '/';
                  final showMiniPlayer = hasSong && !isNowPlaying && !isSplash;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: showMiniPlayer
                                ? AppDimensions.miniPlayerHeight
                                : 0.0,
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                      if (showMiniPlayer)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: const MiniPlayerBar(),
                        ),
                      // DebugPanel directly in Stack (it manages its own Positioned)
                      const DebugPanel(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}