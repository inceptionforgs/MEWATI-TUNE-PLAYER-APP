// File: lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/ad_banner_widget.dart';
import '../../core/widgets/connectivity_banner.dart';
import '../../core/widgets/app_drawer.dart';
import '../songs/songs_screen.dart';
import '../singers/singers_screen.dart';
import '../trending/trending_screen.dart';
import '../favorites/favorites_screen.dart';
import '../downloads/downloads_screen.dart';
import '../search/search_screen.dart';
import 'widgets/brand_row.dart';
import 'widgets/home_tabs.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Fixed (P5-4): only tab 0 (Songs) is "visited" at startup. The other 4
  // tabs' screens are not built at all until the user actually taps them —
  // previously IndexedStack built all 5 screens immediately on launch,
  // firing 5 simultaneous data fetches (Downloads also separately called
  // loadSongs, doubling one of them). Once a tab is built here, IndexedStack
  // keeps it mounted (just hidden) when switching away, so this also gives
  // "keep alive" behavior for free — no re-fetch on returning to a tab.
  final Set<int> _visitedTabs = {0};

  static final List<Widget Function()> _screenBuilders = [
    () => const SongsScreen(),
    () => const SingersScreen(),
    () => const TrendingScreen(),
    () => const FavoritesScreen(),
    () => const DownloadsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // No duplicate data loading here.
    // Each tab screen (SongsScreen, SingersScreen, etc.) is responsible for
    // loading its own data when it is first built.
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: t.background,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: t.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const ConnectivityBanner(),
              BrandRow(
                onMenuTap: _openDrawer,
                onSearchTap: _openSearch,
              ),
              HomeTabs(
                currentIndex: _currentIndex,
                onTabSelected: _onTabSelected,
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: List.generate(_screenBuilders.length, (i) {
                    return _visitedTabs.contains(i)
                        ? _screenBuilders[i]()
                        : const SizedBox.shrink();
                  }),
                ),
              ),
              // MiniPlayerBar is now provided globally via MaterialApp.builder overlay
              // (see lib/app.dart). Removing it here prevents duplicate control decks
              // and ensures it appears on all pushed routes.
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
