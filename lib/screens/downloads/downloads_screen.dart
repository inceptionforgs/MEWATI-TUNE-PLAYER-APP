import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/song_row.dart';
import '../../models/song.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/songs_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final songsProvider = Provider.of<SongsProvider>(context, listen: false);
      final downloadsProvider =
          Provider.of<DownloadsProvider>(context, listen: false);

      if (songsProvider.allSongs.isEmpty) {
        await songsProvider.loadSongs();
      }
      await downloadsProvider.checkExistingDownloads(songsProvider.allSongs);
    });
  }

  void _playSong(Song song) {
    Provider.of<PlayerProvider>(context, listen: false).playSong(song);
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

  Future<void> _removeDownload(String songId) async {
    final downloadsProvider =
        Provider.of<DownloadsProvider>(context, listen: false);
    try {
      await downloadsProvider.removeDownload(songId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from downloads'),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove download'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songsProvider = context.watch<SongsProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final likesProvider = context.watch<LikesProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final currentSongId = context.select<PlayerProvider, String?>(
      (p) => p.currentSong?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.isPlaying,
    );

    if (songsProvider.isLoading) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (songsProvider.errorMessage != null && songsProvider.allSongs.isEmpty) {
      return AppErrorWidget(
        error: songsProvider.errorMessage,
        onRetry: () => songsProvider.loadSongs(),
      );
    }

    final downloadedSongs = songsProvider.allSongs
        .where((song) => downloadsProvider.isDownloaded(song.id))
        .toList();

    if (downloadedSongs.isEmpty) {
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
                child: Icon(Icons.download_outlined,
                    color: t.textPrimary, size: 24),
              ),
              const SizedBox(height: 15),
              Text(
                'No downloads yet',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              Text(
                'Tap the download icon on any song to save it offline.',
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      children: downloadedSongs.map((song) {
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isDownloading = downloadsProvider.isDownloading(song.id);
        final progress = downloadsProvider.getProgress(song.id);
        final isLiked = likesProvider.isLikedSync(song.id);
        final likeCount = likesProvider.getLikeCountSync(song.id) > 0
            ? likesProvider.getLikeCountSync(song.id)
            : song.likeCount;

        return SongRow(
          song: song,
          isNow: isNow,
          isPlaying: isPlaying,
          isFav: isFav,
          isDownloaded: true,
          isDownloading: isDownloading,
          progress: progress,
          t: t,
          isLiked: isLiked,
          likeCount: likeCount,
          onTap: () => _playSong(song),
          onToggleFavorite: () => _toggleFavorite(song),
          onDownload: () => _downloadSong(song),
          onCancelDownload: () => _cancelDownload(song.id),
          onRemoveDownload: () => _removeDownload(song.id),
          onToggleLike: () => likesProvider.toggleLike(song.id),
        );
      }).toList(),
    );
  }
}