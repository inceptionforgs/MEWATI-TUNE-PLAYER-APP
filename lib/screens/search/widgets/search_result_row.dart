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

    return SongRow(
      t: t,
      data: SongRowData(
        song: song,
        isNow: isNow,
        isPlaying: isPlaying,
        isFav: isFav,
        isDownloaded: downloadsProvider.isDownloaded(song.id),
        isDownloading: downloadsProvider.isDownloading(song.id),
        progress: downloadsProvider.getProgress(song.id),
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
        onToggleFavorite: () => favoritesProvider.toggleFavorite(song),
        onDownload: () => downloadsProvider.downloadSong(song),
        onCancelDownload: () => downloadsProvider.cancelDownload(song.id),
        onRemoveDownload: () => downloadsProvider.removeDownload(song.id),
        onToggleLike: () => likesProvider.toggleLike(song.id),
      ),
    );
  }
}