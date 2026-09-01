import 'package:flutter/foundation.dart';
import '../services/like_service.dart';

class LikesProvider extends ChangeNotifier {
  final LikeService _likeService = LikeService();

  final Set<String> _likedSongIds = {};
  final Map<String, int> _likeCounts = {};

  bool _isLoading = false;
  String? _errorMessage;

  Set<String> get likedSongIds => _likedSongIds;
  Map<String, int> get likeCounts => _likeCounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isLikedSync(String songId) => _likedSongIds.contains(songId);
  int getLikeCountSync(String songId) => _likeCounts[songId] ?? 0;

  Future<void> loadLikedSongs(List<String> songIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _likedSongIds.clear();
      for (final id in songIds) {
        final liked = await _likeService.isLiked(id);
        if (liked) {
          _likedSongIds.add(id);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLikeCounts(List<String> songIds) async {
    try {
      for (final id in songIds) {
        final count = await _likeService.getLikeCount(id);
        _likeCounts[id] = count;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleLike(String songId) async {
    _errorMessage = null;
    final wasLiked = _likedSongIds.contains(songId);

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
    } catch (e) {
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
}