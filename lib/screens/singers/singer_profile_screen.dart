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
      likesProvider.loadLikesData(_songs.map((s) => s.id).toList());
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

  void _removeDownload(String songId) {
    Provider.of<DownloadsProvider>(context, listen: false)
        .removeDownload(songId);
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
                            'Back to Singers',
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
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 5),
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

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: _songs.asMap().entries.map((entry) {
        final index = entry.key;
        final song = entry.value;
        final isNow = currentSongId == song.id;
        final isFav = favoritesProvider.isFavoriteSync(song.id);
        final isDownloaded = downloadsProvider.isDownloaded(song.id);
        final isDownloading = downloadsProvider.isDownloading(song.id);
        final progress = downloadsProvider.getProgress(song.id);
        final isLiked = likesProvider.isLikedSync(song.id);
        final likeCount = likesProvider.likeCounts.containsKey(song.id)
            ? likesProvider.getLikeCountSync(song.id)
            : song.likeCount;

        return SongRow(
          song: song,
          isNow: isNow,
          isPlaying: isPlaying,
          isFav: isFav,
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
          progress: progress,
          t: t,
          subtitle: song.singerName ?? 'Unknown Artist',
          isLiked: isLiked,
          likeCount: likeCount,
          onTap: () => _playSong(_songs, index),
          onToggleFavorite: () => _toggleFavorite(song),
          onDownload: () => _downloadSong(song),
          onCancelDownload: () => _cancelDownload(song.id),
          onRemoveDownload: () => _removeDownload(song.id),
          onToggleLike: () => likesProvider.toggleLike(song.id),
        );
      }).toList(),
    );
  }
}