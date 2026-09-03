// File: lib/screens/downloads/downloads_screen.dart

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

      // Make sure the provider's own persisted download store (ids + full
      // song data) is loaded.
      await downloadsProvider.initialize();

      // Still verify on-disk files against whatever songs are currently
      // loaded elsewhere in the app (cache-integrity check only — this
      // no longer decides what's SHOWN on this screen, see build() below).
      final songsProvider = Provider.of<SongsProvider>(context, listen: false);
      if (songsProvider.allSongs.isNotEmpty) {
        await downloadsProvider.checkExistingDownloads(songsProvider.allSongs);
      }

      likesProvider.loadLikesData(
        downloadsProvider.downloadedSongsList.map((s) => s.id).toList(),
      );
    });
  }

  void _playSong(List<Song> songs, int index) {
    Provider.of<PlayerProvider>(context, listen: false).setPlaylist(
      songs: songs,
      startIndex: index,
    );
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

  // Fixed: audioUrl is now required (File 36) so the correct file/extension
  // actually gets deleted from disk, and the result is checked to show the
  // right SnackBar instead of assuming success via try/catch on a void call.
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

    // Fixed: this list now comes from the provider's own persisted
    // downloaded-songs store, NOT from SongsProvider.allSongs (which is
    // only a paginated subset). A song downloaded from Search or Trending
    // that was never in the first loaded page now correctly shows up here.
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
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      itemCount: downloadedSongs.length,
      itemBuilder: (context, index) {
        final song = downloadedSongs[index];
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isDownloading = downloadsProvider.isDownloading(song.id);
        final progress = downloadsProvider.getProgress(song.id);
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
            onRemoveDownload: () => _removeDownload(song),
            onToggleLike: () => likesProvider.toggleLike(song.id),
          ),
        );
      },
    );
  }
}
