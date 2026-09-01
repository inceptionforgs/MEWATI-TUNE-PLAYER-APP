import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/ad_banner_widget.dart';
import '../../core/widgets/connectivity_banner.dart';
import '../../core/widgets/mini_player_bar.dart';
import '../../core/widgets/app_drawer.dart';
import '../songs/songs_screen.dart';
import '../singers/singers_screen.dart';
import '../trending/trending_screen.dart';
import '../favorites/favorites_screen.dart';
import '../downloads/downloads_screen.dart';
import '../search/search_screen.dart';
import 'widgets/brand_row.dart';
import 'widgets/home_tabs.dart';
import '../../providers/songs_provider.dart';
import '../../providers/singers_provider.dart';
import '../../providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _screens = [
    SongsScreen(),
    SingersScreen(),
    TrendingScreen(),
    FavoritesScreen(),
    DownloadsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final songsProvider = Provider.of<SongsProvider>(context, listen: false);
      if (songsProvider.allSongs.isEmpty) {
        songsProvider.loadSongs();
      }
      final singersProvider = Provider.of<SingersProvider>(context, listen: false);
      if (singersProvider.allSingers.isEmpty) {
        singersProvider.loadSingers();
      }
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
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
                onTabSelected: (index) => setState(() => _currentIndex = index),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
              ),
              const MiniPlayerBar(),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}