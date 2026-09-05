import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/ad_banner_widget.dart';
import '../../core/widgets/app_drawer.dart';
import '../../routes/route_names.dart';
import '../songs/songs_screen.dart';
import '../singers/singers_screen.dart';
import '../trending/trending_screen.dart';
import '../favorites/favorites_screen.dart';
import '../downloads/downloads_screen.dart';
import '../search/search_screen.dart';
import 'widgets/brand_row.dart';
import 'widgets/home_tabs.dart';
import '../../providers/theme_provider.dart';

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController;

  final Set<int> _visitedTabs = {};

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
    _pageController = PageController(initialPage: _currentIndex);
    _markVisited(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markVisited(int index) {
    _visitedTabs.add(index);
    if (index > 0) _visitedTabs.add(index - 1);
    if (index < _screenBuilders.length - 1) _visitedTabs.add(index + 1);
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _markVisited(index);
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _markVisited(index);
    });
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SearchScreen(),
        fullscreenDialog: true,
        settings: const RouteSettings(name: RouteNames.search),
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
              BrandRow(
                onMenuTap: _openDrawer,
                onSearchTap: _openSearch,
              ),
              HomeTabs(
                currentIndex: _currentIndex,
                onTabSelected: _onTabSelected,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _screenBuilders.length,
                  itemBuilder: (context, i) {
                    return _visitedTabs.contains(i)
                        ? _KeepAlivePage(child: _screenBuilders[i]())
                        : const SizedBox.shrink();
                  },
                ),
              ),
              const AdBannerWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
