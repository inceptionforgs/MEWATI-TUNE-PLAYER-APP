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
      likesProvider.loadLikesData(_trendingSongs.map((s) => s.id).toList());
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
      likesProvider.loadLikesData(_trendingSongs.map((s) => s.id).toList());
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
    Provider.of<PlayerProvider>(context, listen: false).setPlaylist(
      songs: songs,
      startIndex: index,
    );
  }

  void _toggleFavorite(Song song) {
    Provider.of<FavoritesProvider>(context, listen: false).toggleFavorite(song);
  }

  void _downloadSong(Song song) {
    Provider.of<DownloadsProvider>(context, listen: false).downloadSong(song);
  }

  void _cancelDownload(String songId) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .cancelDownload(songId);
  }

  void _removeDownload(String songId, {required String audioUrl}) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .removeDownload(songId, audioUrl: audioUrl);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    final currentSongId = context.select<PlayerProvider, String?>(
      (p) => p.currentSong?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.isPlaying,
    );

    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final likesProvider = context.watch<LikesProvider>();

    if (_isLoading && _trendingSongs.isEmpty) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (_errorMessage != null && _trendingSongs.isEmpty) {
      return AppErrorWidget(error: _errorMessage, onRetry: _loadFirstPage);
    }

    if (_trendingSongs.isEmpty && !_isLoading) {
      return Center(
        child: Text(AppStrings.noSongsFound,
            style: TextStyle(color: t.textSecondary)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _trendingSongs.length +
          (_isLoadingMore || _loadMoreError != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _trendingSongs.length) {
          if (_loadMoreError != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Couldn\'t load more songs',
                      style: TextStyle(color: t.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _loadMore,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final song = _trendingSongs[index];
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isDownloaded = downloadsProvider.isDownloaded(song.id);
        final isDownloading = downloadsProvider.isDownloading(song.id);
        final progress = downloadsProvider.getProgress(song.id);
        final isLiked = likesProvider.isLikedSync(song.id);
        final likeCount = likesProvider.likeCounts.containsKey(song.id)
            ? likesProvider.getLikeCountSync(song.id)
            : song.likeCount;

        return SongRow(
          t: t,
          data: SongRowData(
            song: song,
            isNow: isNow,
            isPlaying: isPlaying,
            isFav: isFav,
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            progress: progress,
            subtitle:
                '${song.singerName ?? "Unknown Artist"} · Plays: ${song.playCount}',
            isLiked: isLiked,
            likeCount: likeCount,
          ),
          actions: SongRowActions(
            onTap: () => _playSong(_trendingSongs, index),
            onToggleFavorite: () => _toggleFavorite(song),
            onDownload: () => _downloadSong(song),
            onCancelDownload: () => _cancelDownload(song.id),
            onRemoveDownload: () => _removeDownload(song.id, audioUrl: song.audioUrl),
            onToggleLike: () => likesProvider.toggleLike(song.id),
          ),
        );
      },
    );
  }
}
