import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/formatters.dart';
import '../../models/song.dart';

class SongRow extends StatelessWidget {
  final Song song;
  final bool isNow;
  final bool isPlaying;
  final bool isFav;
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final dynamic t;
  final String? subtitle;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDownload;
  final VoidCallback onCancelDownload;
  final VoidCallback onRemoveDownload;
  final VoidCallback onToggleLike;

  const SongRow({
    Key? key,
    required this.song,
    required this.isNow,
    required this.isPlaying,
    required this.isFav,
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.t,
    this.subtitle,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDownload,
    required this.onCancelDownload,
    required this.onRemoveDownload,
    required this.onToggleLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isNow
              ? Colors.black.withOpacity(0.45)
              : Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: isNow
              ? Border(left: BorderSide(color: t.textPrimary, width: 4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.textPrimary.withOpacity(0.24), width: 2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A170D), Color(0xFF120C08)],
                ),
              ),
              child: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: song.coverImageUrl!,
                        fit: BoxFit.cover,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: t.textPrimary.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPlaying ? 'Ⅱ NOW' : '▶ NOW',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            else ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: isLiked ? t.accent : t.textPrimary.withOpacity(0.75),
                      size: 20,
                    ),
                    onPressed: onToggleLike,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.redAccent : t.textPrimary.withOpacity(0.75),
                ),
                onPressed: onToggleFavorite,
              ),
              if (isDownloaded)
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF4CD964)),
                  onPressed: onRemoveDownload,
                )
              else if (isDownloading)
                GestureDetector(
                  onTap: onCancelDownload,
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
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.download_outlined,
                    color: t.textPrimary.withOpacity(0.75),
                  ),
                  onPressed: onDownload,
                ),
            ],
          ],
        ),
      ),
    );
  }
}