import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/player_service.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService = PlayerService();

  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSong => _currentSong != null;

  bool get shuffleMode => _playerService.shuffleMode;
  LoopMode get loopMode => _playerService.loopMode;

  int get currentQueueIndex => _playerService.currentIndex;
  int get totalQueueLength => _playerService.playlist.length;

  /// Read-only view of the current queue — used by Drive Mode (File 32)
  /// to show the larger, simplified song list without duplicating
  /// PlayerService's playlist state anywhere.
  List<Song> get queue => _playerService.playlist;

  PlayerProvider() {
    _init();
  }

  void _init() {
    _playerStateSubscription = _playerService.playerStateStream.listen((PlayerState state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
      }
      notifyListeners();
    });

    _positionSubscription = _playerService.positionStream.listen((Duration pos) {
      _position = pos;
      notifyListeners();
    });

    _durationSubscription = _playerService.durationStream.listen((Duration? dur) {
      _duration = dur;
      notifyListeners();
    });

    _currentIndexSubscription = _playerService.currentIndexStream.listen((int? index) {
      if (index == null) return;
      final playlist = _playerService.playlist;
      if (index >= 0 && index < playlist.length) {
        final newSong = playlist[index];
        if (_currentSong?.id != newSong.id) {
          _currentSong = newSong;
          notifyListeners();
        }
      }
    });
  }

  Future<void> playSong(Song song) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _playerService.playSong(song);
      // After playback starts, get the actual current song from the service
      // (in case the service filtered or adjusted the playlist).
      _currentSong = _playerService.currentSong;
    } catch (e) {
      _errorMessage = 'Playback failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPlaylist({required List<Song> songs, required int startIndex}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _playerService.setPlaylist(songs: songs, startIndex: startIndex);
      // Use the service's actual current song, not the original list reference,
      // because the service may filter out unplayable songs and adjust the index.
      _currentSong = _playerService.currentSong;
    } catch (e) {
      _errorMessage = 'Playback failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    _errorMessage = null;
    try {
      await _playerService.togglePlayPause();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    _errorMessage = null;
    try {
      await _playerService.seek(position);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> next() async {
    _errorMessage = null;
    try {
      await _playerService.next();
      final song = _playerService.currentSong;
      if (song != null) {
        _currentSong = song;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> previous() async {
    _errorMessage = null;
    try {
      await _playerService.previous();
      final song = _playerService.currentSong;
      if (song != null) {
        _currentSong = song;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void toggleShuffle() {
    _playerService.toggleShuffle();
    notifyListeners();
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _errorMessage = null;
    try {
      await _playerService.setLoopMode(mode);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _currentIndexSubscription?.cancel();
    super.dispose();
  }
}
