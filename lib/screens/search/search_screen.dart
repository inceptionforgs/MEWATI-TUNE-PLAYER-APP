import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/debouncer.dart';
import '../../models/song.dart';
import '../../models/singer.dart';
import '../../providers/songs_provider.dart';
import '../../providers/singers_provider.dart';
import '../../providers/theme_provider.dart';
import '../singers/singer_profile_screen.dart';
import 'widgets/search_result_row.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  List<Song> _songResults = [];
  List<Singer> _singerResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

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
      });
      return;
    }

    setState(() => _isLoading = true);

    final songsProvider = context.read<SongsProvider>();
    final singersProvider = context.read<SingersProvider>();

    try {
      final songResultsFuture = songsProvider.searchSongsRemote(term);
      final lowerTerm = term.toLowerCase();
      final singerResults = singersProvider.allSingers
          .where((singer) => singer.name.toLowerCase().contains(lowerTerm))
          .toList();

      final songResults = await songResultsFuture;

      if (!mounted) return;
      setState(() {
        _songResults = songResults;
        _singerResults = singerResults;
        _isSearching = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _songResults = [];
        _singerResults = [];
        _isSearching = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final hasResults = _songResults.isNotEmpty || _singerResults.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
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
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search songs or singers...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: !hasResults
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search,
                              size: 56, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 15),
                          Text(
                            _isSearching ? 'No matches found' : 'Type to Search',
                            style: const TextStyle(
                              color: Colors.white,
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
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 7),
                              child: Text(
                                'Find your favorite Mewati songs & singers instantly.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        if (_singerResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(19, 18, 19, 9),
                            child: Text(
                              'SINGERS (${_singerResults.length})',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.35,
                              ),
                            ),
                          ),
                          ..._singerResults.map((singer) => _buildSingerResultRow(singer, t)),
                        ],
                        if (_songResults.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(19, 18, 19, 9),
                            child: Text(
                              'SONGS (${_songResults.length})',
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.35,
                              ),
                            ),
                          ),
                          ..._songResults.map(
                            (song) => SearchResultRow(song: song, t: t),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingerResultRow(Singer singer, dynamic t) {
    final initial = singer.name.isNotEmpty ? singer.name[0].toUpperCase() : '?';
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
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: t.surface,
              child: Text(
                initial,
                style: TextStyle(color: t.accent, fontWeight: FontWeight.w800),
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
            Icon(Icons.chevron_right, color: t.textPrimary.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}