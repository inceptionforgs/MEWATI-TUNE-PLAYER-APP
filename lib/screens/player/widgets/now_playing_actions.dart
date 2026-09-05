// FILE: lib/screens/player/widgets/now_playing_actions.dart
//
// FIXED (Batch 3 audit):
// - Download progress spinner is now driven by
//   `downloadsProvider.progressNotifier` via ValueListenableBuilder, so it
//   updates on every tick instead of being stuck until the next
//   notifyListeners() call (which previously only fired at start/finish).
// - The downloading state is now tappable to cancel (previously a
//   display-only 36x36 box with no gesture handling).
// - Removing a completed download now asks for confirmation instead of
//   deleting the file immediately on tap.
// - Like count now falls back to `song.likeCount` when LikesProvider
//   hasn't cached a count for this id yet, instead of showing 0.
//
// Icon order (heart -> thumbs(+count) -> download -> timer -> equalizer)
// is unchanged, matching the prototype's np-actions-row order.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/song.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/likes_provider.dart';
import '../../../core/utils/formatters.dart';

class NowPlayingActions extends StatelessWidget {
  final Song song;
  final VoidCallback onTimerTap;
  final VoidCallback onEqualizerTap;

  const NowPlayingActions({
    Key? key,
    required this.song,
    required this.onTimerTap,
    required this.onEqualizerTap,
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

  // FIXED: removing a download now confirms first instead of deleting the
  // file immediately on tap.
  static Future<void> _confirmRemoveDownload(
    BuildContext context,
    DownloadsProvider downloadsProvider,
    Song song,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text('"${song.title}" will be deleted from your downloads.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await downloadsProvider.removeDownload(
      song.id,
      audioUrl: song.audioUrl,
    );
    if (!context.mounted) return;
    if (!success) {
      _showFailureSnackBar(context, 'Failed to remove download');
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final sleepTimerProvider = context.watch<SleepTimerProvider>();
    final likesProvider = context.watch<LikesProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final isFav = favoritesProvider.isFavoriteSync(song.id);
    final isDownloaded = downloadsProvider.isDownloaded(song.id);
    final isDownloading = downloadsProvider.isDownloading(song.id);
    final isTimerActive = sleepTimerProvider.isActive;
    final isLiked = likesProvider.isLikedSync(song.id);
    // FIXED: fall back to the song's own like count when LikesProvider
    // hasn't cached a value for this id yet, instead of showing 0.
    final likeCount = likesProvider.likeCounts.containsKey(song.id)
        ? likesProvider.getLikeCountSync(song.id)
        : song.likeCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Heart (favorite) — first, matching the prototype.
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : t.textPrimary.withOpacity(0.75),
            size: 22,
          ),
          onPressed: () => _toggleFavorite(context, favoritesProvider, song),
        ),
        const SizedBox(width: 18),
        // Thumbs up (like) + count — second.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: isLiked ? const Color(0xFFFFD700) : t.textPrimary.withOpacity(0.75),
                size: 22,
              ),
              onPressed: () => _toggleLike(context, likesProvider, song.id),
            ),
            Text(
              formatCount(likeCount),
              style: TextStyle(
                color: t.textPrimary.withOpacity(0.75),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(width: 18),
        if (isDownloaded)
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 22),
            onPressed: () =>
                _confirmRemoveDownload(context, downloadsProvider, song),
          )
        else if (isDownloading)
          // FIXED: wrapped in an InkWell to cancel, and the progress value
          // now comes from progressNotifier via ValueListenableBuilder so
          // it animates live instead of sitting stuck at 0%.
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => downloadsProvider.cancelDownload(song.id),
            child: SizedBox(
              width: 36,
              height: 36,
              child: ValueListenableBuilder<Map<String, double>>(
                valueListenable: downloadsProvider.progressNotifier,
                builder: (context, progressMap, _) {
                  final progress = progressMap[song.id] ?? 0.0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2.5,
                        color: t.textPrimary,
                      ),
                      Text(
                        '${(progress * 100).round()}',
                        style: TextStyle(fontSize: 8.5, color: t.textPrimary),
                      ),
                    ],
                  );
                },
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(Icons.download_outlined,
                color: t.textPrimary.withOpacity(0.75), size: 22),
            onPressed: () async {
              try {
                await downloadsProvider.downloadSong(song);
              } catch (e) {
                if (!context.mounted) return;
                _showFailureSnackBar(context, 'Download failed. Please try again.');
              }
            },
          ),
        const SizedBox(width: 18),
        IconButton(
          icon: Icon(
            Icons.timer_outlined,
            color: isTimerActive ? t.accent : t.textPrimary.withOpacity(0.75),
            size: 22,
          ),
          onPressed: onTimerTap,
        ),
        const SizedBox(width: 18),
        IconButton(
          icon: Icon(Icons.equalizer,
              color: t.textPrimary.withOpacity(0.75), size: 22),
          onPressed: onEqualizerTap,
        ),
      ],
    );
  }
}
