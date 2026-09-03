// File: lib/screens/favorites/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/song_row.dart';
import '../../models/song.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);
      final likesProvider = Provider.of<LikesProvider>(context, listen: false);

      await favoritesProvider.loadFavorites();

      // Fixed (P5-2): Favorites screen previously never called
      // loadLikesData at all, so hearts/like counts here relied on
      // whatever another screen happened to have already loaded.
      if (favoritesProvider.favoriteSongs.isNotEmpty) {
        likesProvider.loadLikesData(favoritesProvider.favoriteSongs);
      }
    });
  }

  void _playSong(List<Song> songs, int index) {
    Provider.of<PlayerProvider>(context, listen: false).setPlaylist(
      songs: songs,
      startIndex: index,
    );
  }

  void _downloadSong(Song song) {
    Provider.of<DownloadsProvider>(context, listen: false).downloadSong(song);
  }

  void _cancelDownload(String songId) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .cancelDownload(songId);
  }

  // Fixed: audioUrl is now required by DownloadsProvider.removeDownload
  // (File 36) so the correct file/extension actually gets deleted, and the
  // result is checked to show the right SnackBar.
  Future<void> _removeDownload(Song song) async {
    final downloadsProvider =
        Provider.of<DownloadsProvider>(context, listen: false);
    final success = await downloadsProvider.removeDownload(
      song.id,
      audioUrl: song.audioUrl,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Removed from downloads' : 'Failed to remove download',
        ),
        backgroundColor: success ? const Color(0xFFE53935) : Colors.grey,
      ),
    );
  }

  Future<void> _toggleFavorite(Song song) async {
    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);

    final wasFavorite = favoritesProvider.isFavoriteSync(song.id);

    await favoritesProvider.toggleFavorite(song);

    if (!mounted) return;

    if (favoritesProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.grey,
        ),
      );
      favoritesProvider.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasFavorite ? 'Removed from favorites' : 'Added to favorites'),
        backgroundColor: wasFavorite ? const Color(0xFFE53935) : const Color(0xFF4CD964),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final likesProvider = context.watch<LikesProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final currentSongId = context.select<PlayerProvider, String?>(
      (p) => p.currentSong?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.isPlaying,
    );

    if (favoritesProvider.isLoading) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (favoritesProvider.errorMessage != null &&
        favoritesProvider.favoriteSongs.isEmpty) {
      return AppErrorWidget(
        error: favoritesProvider.errorMessage,
        onRetry: () => favoritesProvider.loadFavorites(),
      );
    }

    if (favoritesProvider.favoriteSongs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.textPrimary, width: 2),
                  color: t.textPrimary.withOpacity(0.12),
                ),
                child: Icon(Icons.favorite, color: t.textPrimary, size: 24),
              ),
              const SizedBox(height: 15),
              Text(
                'No favorites yet',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Text(
                'Songs you like will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.65),
              ),
            ],
          ),
        ),
      );
    }

    final favoriteSongs = favoritesProvider.favoriteSongs;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        final isNow = currentSongId == song.id;
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
            isFav: true,
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            progress: progress,
            subtitle: song.singerName ?? 'Unknown Artist',
            isLiked: isLiked,
            likeCount: likeCount,
          ),
          actions: SongRowActions(
            onTap: () => _playSong(favoriteSongs, index),
            onToggleFavorite: () => _toggleFavorite(song),
            onDownload: () => _downloadSong(song),
            onCancelDownload: () => _cancelDownload(song.id),
            onRemoveDownload: () => _removeDownload(song),
            onToggleLike: () => likesProvider.toggleLike(song.id),
          ),
        );
      },
    );
  }
}
