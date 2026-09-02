import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/player_service.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerService _playerService = PlayerService();

  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isBuffering = false;
  String? _errorMessage;

  // position/duration used to live on this ChangeNotifier and fire
  // notifyListeners() on every position tick (~200ms), rebuilding the
  // *entire* widget tree that watches PlayerProvider. They now live on
  // separate ValueNotifiers so only the SeekBar / mini-player slider
  // (via ValueListenableBuilder) rebuild on position/duration changes.
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<int?>? _currentIndexSubscription;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventErrorSubscription;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  bool get hasSong => _currentSong != null;

  // Kept for any existing call sites that read a snapshot value directly
  // (prefer positionNotifier/durationNotifier for UI that rebuilds on tick).
  Duration get position => positionNotifier.value;
  Duration? get duration => durationNotifier.value;

  bool get shuffleMode => _playerService.shuffleMode;
  LoopMode get loopMode => _playerService.loopMode;

  int get currentQueueIndex => _playerService.currentIndex;
  int get totalQueueLength => _playerService.playlist.length;

  PlayerProvider() {
    _init();
  }

  void _init() {
    _playerStateSubscription = _playerService.playerStateStream.listen((PlayerState state) {
      _isPlaying = state.playing;
      _isBuffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      if (state.processingState == ProcessingState.completed) {
        _isPlaying = false;
      }
      notifyListeners();
    });

    // position/duration no longer call notifyListeners() on this
    // ChangeNotifier — they update the dedicated ValueNotifiers instead.
    _positionSubscription = _playerService.positionStream.listen((Duration pos) {
      positionNotifier.value = pos;
    });

    _durationSubscription = _playerService.durationStream.listen((Duration? dur) {
      durationNotifier.value = dur;
    });

    // Single source of truth for "current song changed": only updates
    // _currentSong once the index stream reports an index that actually
    // maps to a different song id. Replaces the old next()/previous()
    // logic that read _currentIndex immediately after seekToNext /
    // seekToPrevious, which was still stale at that point.
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

    // Surface real playback errors instead of only debugPrint-ing them.
    // just_audio delivers playback failures as errors on the playback
    // event stream.
    _playbackEventErrorSubscription = _playerService.player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) {
        _errorMessage = 'Unable to play this song. Check your internet connection and retry.';
        _isLoading = false;
        _isBuffering = false;
        notifyListeners();
      },
    );
  }

  Future<void> setPlaylist({required List<Song> songs, required int startIndex}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gate playback until JustAudioBackground has actually finished
      // initializing (main.dart now awaits this before runApp — File 5 —
      // but we still guard defensively here).
      await _playerService.ensureReady();
      await _playerService.setPlaylist(songs: songs, startIndex: startIndex);
      _currentSong = _playerService.currentSong;
    } catch (e) {
      _errorMessage = 'Unable to play this song. Check your internet connection and retry.';
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
      _errorMessage = 'Unable to play this song. Check your internet connection and retry.';
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
      // Current-song update now happens exclusively via
      // _currentIndexSubscription above.
    } catch (e) {
      _errorMessage = 'Unable to play this song. Check your internet connection and retry.';
      notifyListeners();
    }
  }

  Future<void> previous() async {
    _errorMessage = null;
    try {
      await _playerService.previous();
      // Current-song update now happens exclusively via
      // _currentIndexSubscription above.
    } catch (e) {
      _errorMessage = 'Unable to play this song. Check your internet connection and retry.';
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
    _processingStateSubscription?.cancel();
    _playbackEventErrorSubscription?.cancel();
    positionNotifier.dispose();
    durationNotifier.dispose();
    super.dispose();
  }
}
