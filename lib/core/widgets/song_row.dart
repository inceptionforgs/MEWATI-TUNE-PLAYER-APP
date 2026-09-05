// FILE: lib/core/widgets/song_row.dart
//
// Restyled to match the prototype's .song-row: consistent card border
// on every row (not just the "now playing" one), per-theme corner
// radius, and icon order reordered to heart -> thumbs(+count) -> download
// (was thumbs -> heart -> download). All data/action wiring
// (SongRowData, SongRowActions, callbacks) is unchanged.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/formatters.dart';
import '../../models/song.dart';
import '../../services/app_cache_manager.dart';
import '../constants/themes/app_theme_id.dart';

/// Holds all visual state needed by [SongRow].
class SongRowData {
  final Song song;
  final bool isNow;
  final bool isPlaying;
  final bool isFav;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final String? subtitle;
  final bool isLiked;
  final int likeCount;

  const SongRowData({
    required this.song,
    required this.isNow,
    required this.isPlaying,
    required this.isFav,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    this.subtitle,
    required this.isLiked,
    required this.likeCount,
  });
}

/// Holds all callbacks used by [SongRow].
class SongRowActions {
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onRemoveDownload;
  final VoidCallback onToggleLike;

  const SongRowActions({
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDownload,
    required this.onCancelDownload,
    required this.onRemoveDownload,
    required this.onToggleLike,
  });
}

class SongRow extends StatelessWidget {
  final SongRowData data;
  final SongRowActions actions;
  final dynamic t;

  const SongRow({
    Key? key,
    required this.data,
    required this.actions,
    required this.t,
  }) : super(key: key);

  /// Card corner radius per theme — matches the prototype's
  /// --card-radius / --thumb-radius tokens (14 default / 4 cyber-black
  /// / 10 silver-chrome for the card; thumb uses the same value here
  /// for simplicity since the prototype keeps them close for song rows).
  static double _radius(AppThemeId id) {
    switch (id) {
      case AppThemeId.cyberBlack:
        return 4;
      case AppThemeId.silverChrome:
        return 10;
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = data.song;
    final isNow = data.isNow;
    final isPlaying = data.isPlaying;
    final isFav = data.isFav;
    final isDownloaded = data.isDownloaded;
    final isDownloading = data.isDownloading;
    final progress = data.progress;
    final subtitle = data.subtitle;
    final isLiked = data.isLiked;
    final likeCount = data.likeCount;
    final radius = _radius(t.id as AppThemeId);

    return InkWell(
      onTap: actions.onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isNow
              ? t.surface.withOpacity(0.45)
              : Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.18)).copyWith(
            left: isNow
                ? BorderSide(color: t.textPrimary, width: 4)
                : BorderSide(color: Colors.white.withOpacity(0.18)),
          ),
        ),
        child: Row(
          children: [
            Semantics(
              label: isNow && isPlaying ? 'Pause' : 'Play',
              button: true,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius - 2 < 0 ? 0 : radius - 2),
                  border: Border.all(color: t.textPrimary.withOpacity(0.24), width: 2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    // Fixed (Item 12): theme-derived gradient (was a
                    // hardcoded pair of colors that never changed with the
                    // active theme), same approach as album_art.dart.
                    colors: [t.surface, t.background],
                  ),
                ),
                child: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(radius - 4 < 0 ? 0 : radius - 4),
                        child: CachedNetworkImage(
                          imageUrl: song.coverImageUrl!,
                          fit: BoxFit.cover,
                          cacheManager: AppCacheManager.instance,
                          memCacheWidth: 128,
                          memCacheHeight: 128,
                          placeholder: (context, url) => Icon(
                            isNow && isPlaying ? Icons.pause : Icons.play_arrow,
                            color: t.textPrimary,
                          ),
                          errorWidget: (context, url, error) => Icon(
                            isNow && isPlaying ? Icons.pause : Icons.play_arrow,
                            color: t.textPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        isNow && isPlaying ? Icons.pause : Icons.play_arrow,
                        color: t.textPrimary,
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ?? (song.category ?? 'Unknown'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary.withOpacity(0.70),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isNow)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.textPrimary.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(radius - 6 < 4 ? 4 : radius - 6),
                  ),
                  child: Text(
                    isPlaying ? 'Ⅱ NOW' : '▶ NOW',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            // Reordered to match the prototype: heart, then thumbs(+count),
            // then download.
            Semantics(
              label: isFav ? 'Remove from favorites' : 'Add to favorites',
              button: true,
              child: IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : t.textPrimary.withOpacity(0.75),
                ),
                onPressed: actions.onToggleFavorite,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: isLiked ? 'Unlike song' : 'Like song',
                  button: true,
                  child: IconButton(
                    icon: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: isLiked ? const Color(0xFFFFD700) : t.textPrimary.withOpacity(0.75),
                      size: 20,
                    ),
                    onPressed: actions.onToggleLike,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
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
            if (isDownloaded)
              Semantics(
                label: 'Remove download',
                button: true,
                child: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF4CD964)),
                  onPressed: actions.onRemoveDownload,
                ),
              )
            else if (isDownloading)
              Semantics(
                label: 'Cancel download',
                button: true,
                child: GestureDetector(
                  onTap: actions.onCancelDownload,
                  child: SizedBox(
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
                  ),
                ),
              )
            else
              Semantics(
                label: 'Download song',
                button: true,
                child: IconButton(
                  icon: Icon(
                    Icons.download_outlined,
                    color: t.textPrimary.withOpacity(0.75),
                  ),
                  onPressed: actions.onDownload,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
