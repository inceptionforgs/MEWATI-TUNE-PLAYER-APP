// FILE: lib/screens/search/widgets/search_result_row.dart
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
    // Fixed (Item 11): await the download and show a SnackBar on failure,
    // mirroring the pattern used above for favorite/like toggle errors.
    // downloadSong() rethrows on failure specifically so callers can do
    // this — previously this call was fire-and-forget and errors were
    // silently dropped.
    try {
      await downloadsProvider.downloadSong(song);
    } catch (e) {
      if (!context.mounted) return;
      _showFailureSnackBar(context, 'Failed to download song. Please try again.');
    }
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

    // Fixed (Item 10): consume downloadsProvider.progressNotifier via
    // ValueListenableBuilder so this row's progress actually animates
    // during a download — progressNotifier deliberately never calls
    // notifyListeners(), so reading getProgress()/isDownloading() directly
    // in build() was stale until some unrelated rebuild happened to occur.
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
              // Play the full search results list starting at this song.
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
            onRemoveDownload: () => downloadsProvider.removeDownload(
              song.id,
              audioUrl: song.audioUrl,
            ),
            onToggleLike: () => _toggleLike(context, likesProvider, song.id),
          ),
        );
      },
    );
  }
}
