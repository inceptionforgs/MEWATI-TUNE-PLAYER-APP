import 'package:flutter/material.dart';
import '../models/singer.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/singers/singer_profile_screen.dart';
import '../screens/player/now_playing_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case RouteNames.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case RouteNames.singerProfile:
        final singer = settings.arguments;
        if (singer is! Singer) {
          return MaterialPageRoute(
            builder: (_) => const HomeScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => SingerProfileScreen(singer: singer),
          settings: settings,
        );
      case RouteNames.nowPlaying:
        return MaterialPageRoute(
          builder: (_) => const NowPlayingScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
