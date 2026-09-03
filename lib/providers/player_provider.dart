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

  // Fixed (Serial 2): lightweight position/duration notifiers so widgets
  // like mini_player_bar can rebuild via ValueListenableBuilder instead of
  // context.watch/select on the whole provider. These are updated on every
  // stream tick WITHOUT calling notifyListeners() themselves.
  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> durationNotifier =
      ValueNotifier<Duration>(Duration.zero);

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

    // Note: notifyListeners() is kept here (not stripped) because
    // drive_mode_screen.dart still reads playerProvider.position via
    // context.watch and needs it to update every tick. mini_player_bar.dart
    // no longer depends on this notifyListeners() call — it listens to
    // positionNotifier directly below.
    _positionSubscription = _playerService.positionStream.listen((Duration pos) {
      _position = pos;
      positionNotifier.value = pos;
      notifyListeners();
    });

    _durationSubscription = _playerService.durationStream.listen((Duration? dur) {
      _duration = dur;
      durationNotifier.value = dur ?? Duration.zero;
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

  // Fixed (Serial 2): PlayerService.playSong(Song) was deleted from
  // PlayerService (only setPlaylist remains). This method had no callers
  // anywhere else in the codebase, so it is removed entirely rather than
  // reimplemented. Use setPlaylist(songs: [song], startIndex: 0) instead.

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
    positionNotifier.dispose();
    durationNotifier.dispose();
    super.dispose();
  }
}
