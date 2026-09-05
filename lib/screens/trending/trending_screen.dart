import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/song_row.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/songs_service.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({Key? key}) : super(key: key);

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final SongsService _songsService = SongsService();
  final ScrollController _scrollController = ScrollController();

  List<Song> _trendingSongs = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _loadMoreError;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final page = await _songsService.fetchTrendingPage(
        offset: 0,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _trendingSongs = page;
        _page = 0;
        _hasMore = page.length >= _pageSize;
      });

      final likesProvider = Provider.of<LikesProvider>(context, listen: false);
      likesProvider.loadLikesData(_trendingSongs);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _trendingSongs = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });
    try {
      final nextPage = await _songsService.fetchTrendingPage(
        offset: (_page + 1) * _pageSize,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        if (nextPage.isEmpty) {
          _hasMore = false;
        } else {
          _trendingSongs.addAll(nextPage);
          _page++;
          _hasMore = nextPage.length >= _pageSize;
        }
      });

      final likesProvider = Provider.of<LikesProvider>(context, listen: false);
      likesProvider.loadLikesData(nextPage);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadMoreError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _playSong(List<Song> songs, int index) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final tappedSong = songs[index];
    if (playerProvider.currentSong?.id == tappedSong.id) {
      playerProvider.togglePlayPause();
      return;
    }
    playerProvider.setPlaylist(
      songs: songs,
      startIndex: index,
    );
  }

  void _showFailureSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.grey),
    );
  }

  Future<void> _toggleFavorite(Song song) async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);
    await favoritesProvider.toggleFavorite(song);
    if (!mounted) return;
    if (favoritesProvider.errorMessage != null) {
      _showFailureSnackBar('Something went wrong. Please try again.');
      favoritesProvider.clearError();
    }
  }

  Future<void> _toggleLike(String songId) async {
    final likesProvider = Provider.of
