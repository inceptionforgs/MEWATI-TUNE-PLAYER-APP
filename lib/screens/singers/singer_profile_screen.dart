import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_strings.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/song_row.dart';
import '../../models/singer.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/downloads_provider.dart';
import '../../providers/likes_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/songs_provider.dart';
import '../../services/app_cache_manager.dart';

class SingerProfileScreen extends StatefulWidget {
  final Singer singer;

  const SingerProfileScreen({Key? key, required this.singer}) : super(key: key);

  @override
  State<SingerProfileScreen> createState() => _SingerProfileScreenState();
}

class _SingerProfileScreenState extends State<SingerProfileScreen> {
  List<Song> _songs = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    Future.microtask(() {
      Provider.of<FavoritesProvider>(context, listen: false).loadFavorites();
    });
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final songs = await Provider.of<SongsProvider>(context, listen: false)
          .fetchSongsBySinger(widget.singer.id);
      if (!mounted) return;
      setState(() => _songs = songs);

      final likesProvider = Provider.of<LikesProvider>(context, listen: false);
      likesProvider.loadLikesData(_songs);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _songs = [];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _playSong(List<Song> songs, int index) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final tappedSong = songs[index];
    if (playerProvider.currentSong?.id == tappedSong.id) {
      playerProvider.togglePlayPause();
      return;
    }
    playerProvider.setPlaylist(
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

    if (confirmed != true) return;

    final success = await Provider.of<DownloadsProvider>(context, listen: false)
        .removeDownload(song.id, audioUrl: song.audioUrl);
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
    final t = context.watch<ThemeProvider>().theme;

    final currentSongId = context.select<PlayerProvider, String?>(
      (p) => p.currentSong?.id,
    );
    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => p.isPlaying,
    );

    final favoritesProvider = context.watch<FavoritesProvider>();
    final downloadsProvider = context.watch<DownloadsProvider>();
    final likesProvider = context.watch<LikesProvider>();

    final initial = widget.singer.name.isNotEmpty
        ? widget.singer.name[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: t.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: t.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chevron_left,
                              color: t.textPrimary, size: 22),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 19),
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: t.textPrimary, width: 2),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B180D), Color(0xFF120C08)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black38,
                              blurRadius: 25,
                              offset: Offset(0, 10)),
                        ],
                      ),
                      child: (widget.singer.photoUrl != null &&
                              widget.singer.photoUrl!.isNotEmpty)
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.singer.photoUrl!,
                                fit: BoxFit.cover,
                                cacheManager: AppCacheManager.instance,
                                memCacheWidth: 160,
                                memCacheHeight: 160,
                                placeholder: (context, url) => Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 34,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: t.textPrimary,
                                      fontSize: 34,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: t.textPrimary,
                                  fontSize: 34,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.singer.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (!_isLoading && _errorMessage == null)
                      Text(
                        '${_songs.length} songs',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: t.textPrimary.withOpacity(0.70),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                  color: t.textPrimary.withOpacity(0.15),
                  height: 2,
                  thickness: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(19, 18, 19, 9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SONGS BY ${widget.singer.name.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.35,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildBody(
                  t,
                  currentSongId,
                  isPlaying,
                  favoritesProvider,
                  downloadsProvider,
                  likesProvider,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    dynamic t,
    String? currentSongId,
    bool isPlaying,
    FavoritesProvider favoritesProvider,
    DownloadsProvider downloadsProvider,
    LikesProvider likesProvider,
  ) {
    if (_isLoading) {
      return const LoadingWidget(message: AppStrings.loading);
    }
    if (_errorMessage != null) {
      return AppErrorWidget(error: _errorMessage, onRetry: _loadSongs);
    }
    if (_songs.isEmpty) {
      return Center(
        child:
            Text(AppStrings.noSongsFound, style: TextStyle(color: t.textSecondary)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isDownloaded = downloadsProvider.isDownloaded(song.id);
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
                isDownloaded: isDownloaded,
                isDownloading: isDownloading,
                progress: progress,
                subtitle: song.singerName ?? 'Unknown Artist',
                isLiked: isLiked,
                likeCount: likeCount,
              ),
              actions: SongRowActions(
                onTap: () => _playSong(_songs, index),
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
