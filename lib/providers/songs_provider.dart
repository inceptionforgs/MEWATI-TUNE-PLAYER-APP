import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/songs_service.dart';
import '../services/local_cache_service.dart';

class SongsProvider extends ChangeNotifier {
  final SongsService _songsService = SongsService();
  final LocalCacheService _cacheService = LocalCacheService();

  List<Song> _allSongs = [];
  List<Song> _filteredSongs = [];
  bool _isSearchActive = false;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 50;

  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, List<Song>> _songsBySingerCache = {};

  List<Song> get allSongs => _allSongs;
  List<Song> get filteredSongs => _filteredSongs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> loadSongs() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firstPage = await _songsService.fetchSongsPage(
        offset: 0,
        limit: _pageSize,
      );
      _allSongs = firstPage;
      if (!_isSearchActive) {
        _filteredSongs = firstPage;
      }
      _currentPage = 0;
      _hasMore = firstPage.length >= _pageSize;

      await _cacheService.cacheSongs(_allSongs);
    } catch (e) {
      final cached = await _cacheService.getCachedSongs();
      if (cached != null && cached.isNotEmpty) {
        _allSongs = cached;
        if (!_isSearchActive) {
          _filteredSongs = cached;
        }
        _hasMore = false;
      } else {
        _allSongs = [];
        if (!_isSearchActive) {
          _filteredSongs = [];
        }
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreSongs() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = await _songsService.fetchSongsPage(
        offset: (_currentPage + 1) * _pageSize,
        limit: _pageSize,
      );

      if (nextPage.isEmpty) {
        _hasMore = false;
      } else {
        _allSongs.addAll(nextPage);
        if (!_isSearchActive) {
          _filteredSongs = _allSongs;
        }
        _currentPage++;
        _hasMore = nextPage.length >= _pageSize;

        await _cacheService.cacheSongs(_allSongs);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchSongs(String query) async {
    _errorMessage = null;
    notifyListeners();

    if (query.trim().isEmpty) {
      _isSearchActive = false;
      _filteredSongs = _allSongs;
      notifyListeners();
      return;
    }

    _isSearchActive = true;
    try {
      final results = await _songsService.searchSongs(query);
      _filteredSongs = results;
    } catch (e) {
      _filteredSongs = [];
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<List<Song>> searchSongsRemote(String query) async {
    try {
      return await _songsService.searchSongs(query);
    } catch (e) {
      return [];
    }
  }

  Future<List<Song>> fetchSongsBySinger(
    String singerId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _songsBySingerCache.containsKey(singerId)) {
      return _songsBySingerCache[singerId]!;
    }
    try {
      final songs = await _songsService.fetchSongsBySinger(singerId);
      _songsBySingerCache[singerId] = songs;
      return songs;
    } catch (e) {
      final cached = _songsBySingerCache[singerId];
      if (cached != null) return cached;
      rethrow;
    }
  }

  void clearSearch() {
    _isSearchActive = false;
    _filteredSongs = _allSongs;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}