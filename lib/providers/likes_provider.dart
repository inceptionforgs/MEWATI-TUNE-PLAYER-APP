import 'package:flutter/foundation.dart';
import '../services/like_service.dart';

class LikesProvider extends ChangeNotifier {
  final LikeService _likeService = LikeService();

  final Set<String> _likedSongIds = {};
  final Map<String, int> _likeCounts = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Cache of song IDs that have been checked for liked status to avoid re-fetching.
  final Set<String> _likedStatusChecked = {};
  final Set<String> _likeCountChecked = {};

  Set<String> get likedSongIds => _likedSongIds;
  Map<String, int> get likeCounts => _likeCounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isLikedSync(String songId) => _likedSongIds.contains(songId);
  int getLikeCountSync(String songId) => _likeCounts[songId] ?? 0;

  /// Load likes data for a list of song IDs.
  /// Uses caching and only fetches missing IDs.
  Future<void> loadLikesData(List<String> songIds) async {
    if (songIds.isEmpty) return;

    // Determine which song IDs need to be fetched.
    final missingLiked = songIds
        .where((id) => !_likedStatusChecked.contains(id))
        .toList();
    final missingCounts = songIds
        .where((id) => !_likeCountChecked.contains(id))
        .toList();

    if (missingLiked.isEmpty && missingCounts.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadLikedSongs(missingLiked),
        _loadLikeCounts(missingCounts),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLikedSongs(List<String> songIds) async {
    if (songIds.isEmpty) return;
    // Batch fetch liked status. For simplicity, one-by-one but we mark as checked.
    for (final id in songIds) {
      try {
        final liked = await _likeService.isLiked(id);
        if (liked) {
          _likedSongIds.add(id);
        }
        _likedStatusChecked.add(id);
      } catch (_) {
        // Mark as checked to avoid infinite retry; can re-check later if needed.
        _likedStatusChecked.add(id);
      }
    }
  }

  Future<void> _loadLikeCounts(List<String> songIds) async {
    if (songIds.isEmpty) return;
    for (final id in songIds) {
      try {
        final count = await _likeService.getLikeCount(id);
        _likeCounts[id] = count;
        _likeCountChecked.add(id);
      } catch (_) {
        _likeCountChecked.add(id);
      }
    }
  }

  /// Load only liked songs (legacy).
  Future<void> loadLikedSongs(List<String> songIds) async {
    final missing = songIds.where((id) => !_likedStatusChecked.contains(id)).toList();
    if (missing.isNotEmpty) {
      await _loadLikedSongs(missing);
      notifyListeners();
    }
  }

  /// Load only like counts (legacy).
  Future<void> loadLikeCounts(List<String> songIds) async {
    final missing = songIds.where((id) => !_likeCountChecked.contains(id)).toList();
    if (missing.isNotEmpty) {
      await _loadLikeCounts(missing);
      notifyListeners();
    }
  }

  Future<void> toggleLike(String songId) async {
    _errorMessage = null;
    final wasLiked = _likedSongIds.contains(songId);

    // Optimistically update.
    if (wasLiked) {
      _likedSongIds.remove(songId);
      _likeCounts[songId] = (_likeCounts[songId] ?? 0) - 1;
      if (_likeCounts[songId]! < 0) _likeCounts[songId] = 0;
    } else {
      _likedSongIds.add(songId);
      _likeCounts[songId] = (_likeCounts[songId] ?? 0) + 1;
    }
    notifyListeners();

    try {
      if (wasLiked) {
        await _likeService.removeLike(songId);
      } else {
        await _likeService.addLike(songId);
      }
      // Update checked flags after successful server op.
      _likedStatusChecked.add(songId);
      _likeCountChecked.add(songId);
    } catch (e) {
      // Rollback if server fails.
      if (wasLiked) {
        _likedSongIds.add(songId);
        _likeCounts[songId] = (_likeCounts[songId] ?? 0) + 1;
      } else {
        _likedSongIds.remove(songId);
        _likeCounts[songId] = (_likeCounts[songId] ?? 0) - 1;
        if (_likeCounts[songId]! < 0) _likeCounts[songId] = 0;
      }
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Invalidate cache for a specific song (e.g., after external changes).
  void invalidateCache(String songId) {
    _likedStatusChecked.remove(songId);
    _likeCountChecked.remove(songId);
  }

  /// Clear all cached data (e.g., on logout).
  void clear() {
    _likedSongIds.clear();
    _likeCounts.clear();
    _likedStatusChecked.clear();
    _likeCountChecked.clear();
    notifyListeners();
  }
}