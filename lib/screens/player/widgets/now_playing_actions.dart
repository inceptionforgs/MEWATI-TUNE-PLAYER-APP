// FILE: lib/screens/player/widgets/now_playing_actions.dart
//
// Reordered icons to match the prototype's np-actions-row order:
// heart -> thumbs(+count) -> download -> timer -> equalizer.
// (Was: thumbs -> heart -> download -> timer -> equalizer.)
// All provider calls/callbacks are unchanged.

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
    final progress = downloadsProvider.getProgress(song.id);
    final isTimerActive = sleepTimerProvider.isActive;
    final isLiked = likesProvider.isLikedSync(song.id);
    final likeCount = likesProvider.getLikeCountSync(song.id);

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
            onPressed: () async {
              final success = await downloadsProvider.removeDownload(
                song.id,
                audioUrl: song.audioUrl,
              );
              if (!context.mounted) return;
              if (!success) {
                _showFailureSnackBar(context, 'Failed to remove download');
              }
            },
          )
        else if (isDownloading)
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
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
