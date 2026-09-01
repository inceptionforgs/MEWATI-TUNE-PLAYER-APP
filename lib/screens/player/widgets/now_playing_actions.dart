import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/song.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/downloads_provider.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../providers/theme_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final sleepTimerProvider = context.watch<SleepTimerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    final isFav = favoritesProvider.isFavoriteSync(song.id);
    final isDownloaded = downloadsProvider.isDownloaded(song.id);
    final isDownloading = downloadsProvider.isDownloading(song.id);
    final progress = downloadsProvider.getProgress(song.id);
    final isTimerActive = sleepTimerProvider.isActive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : t.textPrimary.withOpacity(0.75),
            size: 22,
          ),
          onPressed: () => favoritesProvider.toggleFavorite(song),
        ),
        const SizedBox(width: 22),
        if (isDownloaded)
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFF4CD964), size: 22),
            onPressed: () => downloadsProvider.removeDownload(song.id),
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
            onPressed: () => downloadsProvider.downloadSong(song),
          ),
        const SizedBox(width: 22),
        IconButton(
          icon: Icon(
            Icons.timer_outlined,
            color: isTimerActive ? t.accent : t.textPrimary.withOpacity(0.75),
            size: 22,
          ),
          onPressed: onTimerTap,
        ),
        const SizedBox(width: 22),
        IconButton(
          icon: Icon(Icons.equalizer,
              color: t.textPrimary.withOpacity(0.75), size: 22),
          onPressed: onEqualizerTap,
        ),
      ],
    );
  }
}