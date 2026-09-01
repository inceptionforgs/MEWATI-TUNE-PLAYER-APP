import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService = FavoritesService();

  List<Song> _favoriteSongs = [];
  final Set<String> _favoriteSongIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  int _requestGeneration = 0;

  List<Song> get favoriteSongs => _favoriteSongs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isFavoriteSync(String songId) => _favoriteSongIds.contains(songId);

  Future<void> loadFavorites() async {
    final int myGeneration = ++_requestGeneration;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final songs = await _favoritesService.fetchFavoriteSongs();

      if (myGeneration != _requestGeneration) return;

      _favoriteSongs = songs;
      _favoriteSongIds
        ..clear()
        ..addAll(songs.map((s) => s.id));
    } catch (e) {
      if (myGeneration != _requestGeneration) return;
      _favoriteSongs = [];
      _errorMessage = e.toString();
    } finally {
      if (myGeneration == _requestGeneration) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Song song) async {
    final int myGeneration = ++_requestGeneration;

    _errorMessage = null;

    final wasFavorite = _favoriteSongIds.contains(song.id);

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
      if (myGeneration != _requestGeneration) return;

      if (wasFavorite) {
        _favoriteSongIds.add(song.id);
        _favoriteSongs.add(song);
      } else {
        _favoriteSongIds.remove(song.id);
        _favoriteSongs.removeWhere((s) => s.id == song.id);
      }
      _errorMessage = e.toString();
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