// FILE: lib/providers/favorites_provider.dart
import 'package:flutter/foundation.dart';
import '../core/utils/error_handler.dart';
import '../models/song.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();

  List<Song> _favoriteSongs = [];
  final Set<String> _favoriteSongIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  // Separate generations: one for load operations, one for toggle operations.
  // This prevents a toggle from invalidating an in‑flight load and leaving
  // the UI stuck in loading state (bug A).
  int _loadGeneration = 0;
  int _toggleGeneration = 0;

  List<Song> get favoriteSongs => _favoriteSongs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavoriteSync(String songId) => _favoriteSongIds.contains(songId);

  Future<void> loadFavorites() async {
    // Prevent duplicate concurrent loads (P1#10).
    if (_isLoading) return;

    final int myGeneration = ++_loadGeneration;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final songs = await _favoritesService.fetchFavoriteSongs();

      // Only apply results if no newer load started.
      if (myGeneration != _loadGeneration) return;

      _favoriteSongs = songs;
      _favoriteSongIds
        ..clear()
        ..addAll(songs.map((s) => s.id));
    } catch (e) {
      if (myGeneration != _loadGeneration) return;
      _favoriteSongs = [];
      _errorMessage = ErrorHandler.getMessage(e);
    } finally {
      // Always clear loading flag for the current load, even if results were ignored.
      if (myGeneration == _loadGeneration) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final int myGeneration = ++_toggleGeneration;

    _errorMessage = null;

    final wasFavorite = _favoriteSongIds.contains(song.id);

    // Optimistically update UI.
    if (wasFavorite) {
      _favoriteSongIds.remove(song.id);
      _favoriteSongs.removeWhere((s) => s.id == song.id);
    } else {
      _favoriteSongIds.add(song.id);
      _favoriteSongs.add(song);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _favoritesService.removeFavorite(song.id);
      } else {
        await _favoritesService.addFavorite(song.id);
      }
    } catch (e) {
      // Rollback only if no newer toggle superseded this one.
      if (myGeneration != _toggleGeneration) return;

      if (wasFavorite) {
        _favoriteSongIds.add(song.id);
        _favoriteSongs.add(song);
      } else {
        _favoriteSongIds.remove(song.id);
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      }
      _errorMessage = ErrorHandler.getMessage(e);
      notifyListeners();
    }
  }

  Future<bool> isFavorite(String songId) async {
    try {
      return await _favoritesService.isFavorite(songId);
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
