import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_dimensions.dart';
import 'core/widgets/debug_panel.dart';
import 'core/widgets/mini_player/mini_player_bar.dart';
import 'services/downloads_service.dart';
import 'services/player_service.dart';
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
import 'routes/route_names.dart';

/// Tracks the currently active top-level route by name so the mini-player
/// can decide whether to show/hide itself. Uses a real NavigatorObserver
/// instead of RouteObserver/RouteAware (which requires a ModalRoute
/// subscriber and isn't meant to be used this way).
class _MiniPlayerRouteObserver extends NavigatorObserver {
  _MiniPlayerRouteObserver(this.onRouteChanged);

  final ValueChanged<String?> onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onRouteChanged(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onRouteChanged(previousRoute?.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    onRouteChanged(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    onRouteChanged(newRoute?.settings.name);
  }
}

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

class _MewatiTunePlayerAppState extends State<MewatiTunePlayerApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<String?> _currentRouteName = ValueNotifier<String?>(null);
  late final _MiniPlayerRouteObserver _routeObserver;

  // Built as instances here (instead of inline inside MultiProvider's
  // `create:` closures) so AuthProvider.onSessionReady can be wired to
  // FavoritesProvider/LikesProvider below — previously onSessionReady was
  // never assigned anywhere, so those providers never reloaded when a
  // session became ready (e.g. after anonymous sign-in completes).
  late final AuthProvider _authProvider;
  late final FavoritesProvider _favoritesProvider;
  late final LikesProvider _likesProvider;
  late final DownloadsProvider _downloadsProvider;

  @override
  void initState() {
    super.initState();
    _routeObserver = _MiniPlayerRouteObserver(
      (name) => _currentRouteName.value = name,
    );
    WidgetsBinding.instance.addObserver(this);

    _authProvider = widget.authProvider ?? AuthProvider();
    _favoritesProvider = FavoritesProvider();
    _likesProvider = LikesProvider();
    _downloadsProvider = widget.downloadsProvider ?? DownloadsProvider();

    // Reload favorites and invalidate the likes cache whenever a session
    // becomes ready, so both providers reflect the now-active session
    // instead of staying stuck empty (or stale from a previous session).
    _authProvider.onSessionReady = () {
      _favoritesProvider.loadFavorites();
      _likesProvider.clear();
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _currentRouteName.dispose();
    super.dispose();
  }

  // Item 15: wire PlayerService's lifecycle handling into the app's real
  // lifecycle. Only AppLifecycleState.detached (app process actually being
  // torn down) calls handleAppDetached() — a normal pause/resume/inactive
  // transition must NOT interrupt background playback, and
  // PlayerService().dispose() (full AudioPlayer teardown) is intentionally
  // never called from here, matching the existing method split in
  // player_service.dart. DownloadsService().dispose() is also called here
  // now (Item 15) so its internal FileDownloader().updates subscription is
  // actually cancelled on app termination, instead of leaking for the
  // app's lifetime.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      PlayerService().handleAppDetached();
      DownloadsService().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<DownloadsProvider>.value(
          value: _downloadsProvider,
        ),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => SongsProvider()),
        ChangeNotifierProvider(create: (_) => SingersProvider()),
        ChangeNotifierProvider<FavoritesProvider>.value(
          value: _favoritesProvider,
        ),
        ChangeNotifierProvider<LikesProvider>.value(value: _likesProvider),
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
            initialRoute: RouteNames.splash,
            builder: (context, child) {
              return ValueListenableBuilder<String?>(
                valueListenable: _currentRouteName,
                builder: (context, routeName, _) {
                  // Watch (not read) hasSong so the mini-player reacts to
                  // playback state changes too, not only route changes.
                  final hasSong = context.select<PlayerProvider, bool>(
                    (p) => p.hasSong,
                  );
                  final isNowPlaying = routeName == RouteNames.nowPlaying;
                  final isSplash = routeName == RouteNames.splash;
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
                          // FIX (nav-bar overlap): previously the
                          // mini-player sat flush at Stack's bottom: 0,
                          // ignoring the device's bottom system-UI inset
                          // entirely. On phones with 3-button (non-gesture)
                          // Android navigation, that inset is non-zero, so
                          // the mini-player rendered underneath/overlapping
                          // the nav buttons. SafeArea adds exactly that
                          // inset as bottom padding (top: false since this
                          // Positioned is already anchored to the bottom,
                          // not the top, of the screen).
                          child: SafeArea(
                            top: false,
                            child: const MiniPlayerBar(),
                          ),
                        ),
                      // Debug-only overlay: never shown to real end users.
                      if (kDebugMode) const DebugPanel(),
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
