import 'package:flutter/material.dart';
import '../models/singer.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/singers/singer_profile_screen.dart';
import '../screens/player/now_playing_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/singer-profile':
        final singer = settings.arguments;
        if (singer is! Singer) {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return MaterialPageRoute(
          builder: (_) => SingerProfileScreen(singer: singer),
        );
      case '/now-playing':
        return MaterialPageRoute(builder: (_) => const NowPlayingScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}