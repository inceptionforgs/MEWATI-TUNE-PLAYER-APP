// lib/screens/downloads/downloads_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      final downloadsProvider =
          Provider.of<DownloadsProvider>(context, listen: false);
      final likesProvider = Provider.of<LikesProvider>(context, listen: false);

      await downloadsProvider.initialize();

      final songsProvider = Provider.of<SongsProvider>(context, listen: false);
      if (songsProvider.allSongs.isNotEmpty) {
        await downloadsProvider.checkExistingDownloads(songsProvider.allSongs);
      }

      likesProvider.loadLikesData(downloadsProvider.downloadedSongsList);
    });
  }

  void _playSong(List<Song> songs, int index) {
    Provider.of<PlayerProvider>(context, listen: false).setPlaylist(
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
    final likesProvider = Provider.of<LikesProvider>(context, listen: false);
    await likesProvider.toggleLike(songId);
    if (!mounted) return;
    if (likesProvider.errorMessage != null) {
      _showFailureSnackBar('Something went wrong. Please try again.');
    }
  }

  Future<void> _downloadSong(Song song) async {
    try {
      await Provider.of<DownloadsProvider>(context, listen: false)
          .downloadSong(song);
    } catch (e) {
      if (!mounted) return;
      _showFailureSnackBar('Failed to download song. Please try again.');
    }
  }

  void _cancelDownload(String songId) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .cancelDownload(songId);
  }

  Future<void> _confirmAndRemoveDownload(Song song) async {
    final t = Provider.of<ThemeProvider>(context, listen: false).theme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Delete download?', style: TextStyle(color: t.textPrimary)),
        content: Text(
          'This will remove "${song.title}" from your downloads.',
          style: TextStyle(color: t.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: t.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeDownload(song);
    }
  }

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

  @override
  Widget build(BuildContext context) {
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

    final downloadedSongs = downloadsProvider.downloadedSongsList;

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

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: 16,
        top: 8,
      ),
      itemCount: downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadedSongs[index];
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isLiked = likesProvider.isLikedSync(song.id);
        final likeCount = likesProvider.likeCounts.containsKey(song.id)
            ? likesProvider.getLikeCountSync(song.id)
            : song.likeCount;

        return ValueListenableBuilder<Map<String, double>>(
          valueListenable: downloadsProvider.progressNotifier,
          builder: (context, progressMap, _) {
            final isDownloading = progressMap.containsKey(song.id);
            final progress = progressMap[song.id] ?? 0.0;

            return SongRow(
              t: t,
              data: SongRowData(
                song: song,
                isNow: isNow,
                isPlaying: isPlaying,
                isFav: isFav,
                isDownloaded: true,
                isDownloading: isDownloading,
                progress: progress,
                subtitle: song.singerName ?? 'Unknown Artist',
                isLiked: isLiked,
                likeCount: likeCount,
              ),
              actions: SongRowActions(
                onTap: () => _playSong(downloadedSongs, index),
                onToggleFavorite: () => _toggleFavorite(song),
                onDownload: () => _downloadSong(song),
                onCancelDownload: () => _cancelDownload(song.id),
                onRemoveDownload: () => _confirmAndRemoveDownload(song),
                onToggleLike: () => _toggleLike(song.id),
              ),
            );
          },
        );
      },
    );
  }
}
