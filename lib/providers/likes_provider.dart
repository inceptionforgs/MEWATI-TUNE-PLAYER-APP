// FILE: lib/providers/likes_provider.dart
import 'package:flutter/foundation.dart';
import '../core/utils/error_handler.dart';
import '../models/song.dart';
import '../services/like_service.dart';

class LikesProvider extends ChangeNotifier {
  final LikeService _likeService;

  // Fixed (Serial 17): LikeService is now optionally injectable so tests
  // can pass a fake implementation instead of the real Supabase-backed
  // singleton. Default behavior (no argument) is unchanged.
  LikesProvider({LikeService? likeService})
      : _likeService = likeService ?? LikeService();

  final Set<String> _likedSongIds = {};
  final Map<String, int> _likeCounts = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Cache of song IDs already checked for liked status, to avoid re-fetching.
  final Set<String> _likedStatusChecked = {};

  Set<String> get likedSongIds => _likedSongIds;
  Map<String, int> get likeCounts => _likeCounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isLikedSync(String songId) => _likedSongIds.contains(songId);
  int getLikeCountSync(String songId) => _likeCounts[songId] ?? 0;

  /// Fixed (P5-2): takes the actual Song list (not just ids) so like counts
  /// are seeded directly from `song.likeCount` — no more per-song count
  /// fetch. Liked-status is fetched in ONE batched query for whatever ids
  /// haven't been checked yet, instead of one request per song.
  Future<void> loadLikesData(List<Song> songs) async {
    if (songs.isEmpty) return;

    // Always keep displayed counts fresh from the payload — cheap, no
    // network call, and avoids the separate per-song count fetch entirely.
    for (final song in songs) {
      _likeCounts[song.id] = song.likeCount;
    }

    final missingLiked = songs
        .map((s) => s.id)
        .where((id) => !_likedStatusChecked.contains(id))
        .toList();

    if (missingLiked.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final likedIds = await _likeService.getLikedSongIds(missingLiked);
      _likedSongIds.addAll(likedIds);
      _likedStatusChecked.addAll(missingLiked);
    } catch (e) {
      _errorMessage = ErrorHandler.getMessage(e);
      // Still mark as checked so a persistent failure doesn't retry forever
      // on every rebuild; loadLikesData can be called again explicitly
      // (e.g. pull-to-refresh) to retry.
      _likedStatusChecked.addAll(missingLiked);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fixed (P1-6/File 9): calls ONLY the `toggle_like` RPC via LikeService,
  /// which does the insert/delete AND the like_count update atomically on
  /// the server. The optimistic UI update is still instant, but on success
  /// the count is overwritten with the server's authoritative value instead
  /// of a client-side +1/-1 guess — this is what prevents desync.
  Future<void> toggleLike(String songId) async {
    _errorMessage = null;
    final wasLiked = _likedSongIds.contains(songId);
    final previousCount = _likeCounts[songId] ?? 0;

    // Optimistic update for instant UI feedback.
    if (wasLiked) {
      _likedSongIds.remove(songId);
      _likeCounts[songId] = (previousCount - 1).clamp(0, previousCount);
    } else {
      _likedSongIds.add(songId);
      _likeCounts[songId] = previousCount + 1;
    }
    notifyListeners();

    try {
      final serverCount = await _likeService.toggleLike(songId);
      _likeCounts[songId] = serverCount;
      _likedStatusChecked.add(songId);
      notifyListeners();
    } catch (e) {
      // Rollback fully to the pre-toggle state on failure.
      if (wasLiked) {
        _likedSongIds.add(songId);
      } else {
        _likedSongIds.remove(songId);
      }
      _likeCounts[songId] = previousCount;
      _errorMessage = ErrorHandler.getMessage(e);
      notifyListeners();
    }
  }

  /// Invalidate cache for a specific song (e.g., after external changes).
  void invalidateCache(String songId) {
    _likedStatusChecked.remove(songId);
  }

  /// Clear all cached data (e.g., on logout).
  void clear() {
    _likedSongIds.clear();
    _likeCounts.clear();
    _likedStatusChecked.clear();
    notifyListeners();
  }
}
