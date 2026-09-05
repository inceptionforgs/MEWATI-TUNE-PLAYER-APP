import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/song_row.dart';
import '../../../models/song.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/likes_provider.dart';
import '../../../providers/theme_provider.dart';

class SearchResultRow extends StatelessWidget {
  final Song song;
  final dynamic t;
  final List<Song> allResults;
  final int index;

  const SearchResultRow({
    Key? key,
    required this.song,
    required this.t,
    required this.allResults,
    required this.index,
  }) : super(key: key);

  static void _showFailureSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.grey),
    );
  }

  static Future<void> _toggleFavorite(
      BuildContext context, FavoritesProvider favoritesProvider, Song song) async {
    await favoritesProvider.toggleFavorite(song);
    if (!context.mounted) return;
    if (favoritesProvider.errorMessage != null) {
      _showFailureSnackBar(context, 'Something went wrong. Please try again.');
      favoritesProvider.clearError();
    }
  }

  static Future<void> _toggleLike(
      BuildContext context, LikesProvider likesProvider, String songId) async {
    await likesProvider.toggleLike(songId);
    if (!context.mounted) return;
    if (likesProvider.errorMessage != null) {
      _showFailureSnackBar(context, 'Something went wrong. Please try again.');
    }
  }

  static Future<void> _downloadSong(
      BuildContext context, DownloadsProvider downloadsProvider, Song song) async {
    try {
      await downloadsProvider.downloadSong(song);
    } catch (e) {
      if (!context.mounted) return;
      _showFailureSnackBar(context, 'Failed to download song. Please try again.');
    }
  }

  static Future<void> _confirmAndRemoveDownload(
      BuildContext context, DownloadsProvider downloadsProvider, Song song) async {
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

    if (confirmed != true) return;

    final success = await downloadsProvider.removeDownload(
      song.id,
      audioUrl: song.audioUrl,
    );
    if (!context.mounted) return;
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
    final currentSongId = context.select<PlayerProvider, String?>(
      (p) => p.currentSong?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.isPlaying,
    );
    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final likesProvider = context.watch<LikesProvider>();

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
            isDownloaded: downloadsProvider.isDownloaded(song.id),
            isDownloading: isDownloading,
            progress: progress,
            subtitle: song.singerName ?? 'Unknown Artist',
            isLiked: isLiked,
            likeCount: likeCount,
          ),
          actions: SongRowActions(
            onTap: () {
              context.read<PlayerProvider>().setPlaylist(
                    songs: allResults,
                    startIndex: index,
                  );
              Navigator.of(context).pop();
            },
            onToggleFavorite: () =>
                _toggleFavorite(context, favoritesProvider, song),
            onDownload: () => _downloadSong(context, downloadsProvider, song),
            onCancelDownload: () => downloadsProvider.cancelDownload(song.id),
            onRemoveDownload: () =>
                _confirmAndRemoveDownload(context, downloadsProvider, song),
            onToggleLike: () => _toggleLike(context, likesProvider, song.id),
          ),
        );
      },
    );
  }
}
