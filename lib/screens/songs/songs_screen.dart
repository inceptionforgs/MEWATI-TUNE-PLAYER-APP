import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/song_row.dart';
import '../../models/song.dart';
import '../../providers/songs_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/theme_provider.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({Key? key}) : super(key: key);

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final songsProvider = Provider.of<SongsProvider>(context, listen: false);
      if (songsProvider.allSongs.isEmpty) {
        songsProvider.loadSongs();
      }
      // Removed duplicate loadFavorites() – FavoritesScreen (mounted in IndexedStack) already handles it.
    });

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
      Provider.of<SongsProvider>(context, listen: false).loadMoreSongs();
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
    Provider.of<DownloadsProvider>(context, listen: false).cancelDownload(songId);
  }

  void _removeDownload(String songId, {required String audioUrl}) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .removeDownload(songId, audioUrl: audioUrl);
  }

  @override
  Widget build(BuildContext context) {
    final songsProvider = context.watch<SongsProvider>();
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

    if (songsProvider.isLoading && songsProvider.allSongs.isEmpty) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (songsProvider.errorMessage != null && songsProvider.allSongs.isEmpty) {
      return AppErrorWidget(
        error: songsProvider.errorMessage,
        onRetry: () => songsProvider.loadSongs(),
      );
    }

    if (songsProvider.filteredSongs.isEmpty && !songsProvider.isLoading) {
      return Center(
        child: Text(AppStrings.noSongsFound,
            style: TextStyle(color: t.textSecondary)),
      );
    }

    final songs = songsProvider.filteredSongs;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: songs.length + (songsProvider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == songs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final song = songs[index];
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
            subtitle: song.singerName ?? 'Unknown Artist',
            isLiked: isLiked,
            likeCount: likeCount,
          ),
          actions: SongRowActions(
            onTap: () => _playSong(songs, index),
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
