// FILE: lib/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_themes.dart';
import '../../core/utils/debouncer.dart';
import '../../core/widgets/error_widget.dart';
import '../../models/song.dart';
import '../../models/singer.dart';
import '../../providers/songs_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/singers_service.dart';
import '../singers/singer_profile_screen.dart';
import 'widgets/search_result_row.dart';

enum _SearchItemType { singerHeader, singerRow, songHeader, songRow }

class _SearchListItem {
  final _SearchItemType type;
  final int index;
  const _SearchListItem(this.type, [this.index = 0]);
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer =
      Debouncer(delay: const Duration(milliseconds: 300));
  final SingersService _singersService = SingersService();

  List<Song> _songResults = [];
  List<Singer> _singerResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  int _searchGeneration = 0; // increments on every new search to discard stale results

  // Fixed (14c): distinct error state — a real search failure (network/API)
  // is now shown via AppErrorWidget with Retry, separate from the genuine
  // "no matches found" empty-results case, which keeps its existing copy.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debouncer.run(() {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final term = query.trim();
    if (term.isEmpty) {
      if (!mounted) return;
      setState(() {
        _songResults = [];
        _singerResults = [];
        _isSearching = false;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    // Invalidate previous searches
    final gen = ++_searchGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final songsProvider = context.read<SongsProvider>();

      // Run both remote searches concurrently.
      // NOTE: singers search goes through SingersService directly (side-effect-free)
      // instead of SingersProvider.searchSingers, which would otherwise overwrite
      // the Singers tab's filteredSingers list as a side effect.
      final results = await Future.wait<dynamic>([
        songsProvider.searchSongsRemote(term),
        _singersService.searchSingers(term),
      ]);

      if (!mounted || gen != _searchGeneration) return;

      final songs = results[0] as List<Song>;
      final singers = results[1] as List<Singer>;

      setState(() {
        _songResults = songs;
        _singerResults = singers;
        _isSearching = true;
        _isLoading = false;
        _errorMessage = null;
      });

      // Load likes for the found songs.
      final likesProvider = Provider.of<LikesProvider>(context, listen: false);
      likesProvider.loadLikesData(_songResults);
    } catch (e) {
      if (!mounted || gen != _searchGeneration) return;
      setState(() {
        _songResults = [];
        _singerResults = [];
        _isSearching = true;
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _retrySearch() {
    _performSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final hasResults = _songResults.isNotEmpty || _singerResults.isNotEmpty;
    final hasError = _errorMessage != null;

    // Flatten singer/song headers + rows into a single item list for
    // ListView.builder so mixed section headers and rows are built lazily.
    final items = <_SearchListItem>[];
    if (_singerResults.isNotEmpty) {
      items.add(const _SearchListItem(_SearchItemType.singerHeader));
      for (var i = 0; i < _singerResults.length; i++) {
        items.add(_SearchListItem(_SearchItemType.singerRow, i));
      }
    }
    if (_songResults.isNotEmpty) {
      items.add(const _SearchListItem(_SearchItemType.songHeader));
      for (var i = 0; i < _songResults.length; i++) {
        items.add(_SearchListItem(_SearchItemType.songRow, i));
      }
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: t.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: t.textPrimary.withOpacity(0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: t.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search songs or singers...',
                          hintStyle: TextStyle(color: t.textSecondary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: t.textPrimary.withOpacity(0.2)),
            if (_isLoading)
              LinearProgressIndicator(minHeight: 2, color: t.accent),
            Expanded(
              child: hasError
                  ? AppErrorWidget(
                      error: _errorMessage,
                      onRetry: _retrySearch,
                    )
                  : !hasResults
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search,
                                  size: 56, color: t.textSecondary),
                              const SizedBox(height: 15),
                              Text(
                                _isSearching
                                    ? 'No matches found'
                                    : 'Type to Search',
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_isSearching)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    'No songs or singers matched "${_searchController.text}".',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    'Find your favorite Mewati songs & singers instantly.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final item = items[i];
                            switch (item.type) {
                              case _SearchItemType.singerHeader:
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(19, 18, 19, 9),
                                  child: Text(
                                    'SINGERS (${_singerResults.length})',
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.35,
                                    ),
                                  ),
                                );
                              case _SearchItemType.singerRow:
                                return _buildSingerResultRow(
                                    _singerResults[item.index], t);
                              case _SearchItemType.songHeader:
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(19, 18, 19, 9),
                                  child: Text(
                                    'SONGS (${_songResults.length})',
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.35,
                                    ),
                                  ),
                                );
                              case _SearchItemType.songRow:
                                return SearchResultRow(
                                  song: _songResults[item.index],
                                  t: t,
                                  allResults: _songResults,
                                  index: item.index,
                                );
                            }
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingerResultRow(Singer singer, AppThemeData t) {
    final initial =
        singer.name.isNotEmpty ? singer.name[0].toUpperCase() : '?';
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SingerProfileScreen(singer: singer),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: t.surface,
              child: Text(
                initial,
                style: TextStyle(
                  color: t.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                singer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}
