import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/media_config.dart';
import '../core/utils/queue_builder.dart';
import '../models/song.dart';
import 'debug_log_service.dart';
import 'downloads_service.dart';
import 'equalizer_service.dart';
import 'songs_service.dart';

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: EqualizerService().androidAudioEffects,
    ),
  );
  final DownloadsService _downloadsService = DownloadsService();
  final SongsService _songsService = SongsService();

  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _shuffleMode = false;
  Timer? _fadeTimer;
  double _originalVolume = 1.0;
  int _fadeToken = 0;

  StreamSubscription<int?>? _internalIndexSubscription;

  String? _playCountTrackedSongId;
  Timer? _playCountTimer;
  final Set<String> _playCountedSongIds = {};
  static const Duration _playCountThreshold = Duration(seconds: 25);

  static bool _notificationPermissionRequested = false;

  static bool _backgroundReady = false;
  static void markReady() => _backgroundReady = true;

  static const int _maxQueueWindow = QueueBuilder.maxQueueWindow;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  AudioPlayer get player => _player;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get shuffleMode => _shuffleMode;
  LoopMode get loopMode => _player.loopMode;

  Song? get currentSong =>
      (_playlist.isNotEmpty && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;

  PlayerService._internal() {
    _internalIndexSubscription = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
        _handleIndexChanged(_playlist[index]);
      }
    });
    _initEqualizer();
  }

  Future<void> ensureReady() async {
    if (_backgroundReady) return;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!_backgroundReady && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _ensureNotificationPermission() async {
    if (_notificationPermissionRequested) return;
    _notificationPermissionRequested = true;
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      DebugLogService().warning('Notification permission request failed: $e');
    }
  }

  Future<void> setPlaylist({
    required List<Song> songs,
    required int startIndex,
  }) async {
    try {
      if (songs.isEmpty) {
        throw Exception('Playlist is empty.');
      }

      final prefs = await SharedPreferences.getInstance();
      final downloadedIds =
          prefs.getStringList('downloaded_song_ids')?.toSet() ?? <String>{};

      final localPaths = <String, String>{};

      for (final song in songs) {
        if (downloadedIds.contains(song.id)) {
          final candidatePath = await _downloadsService.getLocalSongPath(
            song.id,
            audioUrl: song.audioUrl,
          );
          final file = File(candidatePath);
          if (file.existsSync() && file.lengthSync() > 0) {
            localPaths[song.id] = candidatePath;
          } else {
            debugPrint(
                'PlayerService: downloaded file missing/corrupt for "${song.title}", falling back to stream.');
          }
        }
      }

      final eligibleSongs = songs.where((song) {
        if (localPaths.containsKey(song.id)) return true;
        final allowed = MediaConfig.isAllowedAudioUrl(song.audioUrl);
        if (!allowed) {
          debugPrint(
              'PlayerService: rejecting "${song.title}" — audio URL host not in CDN allowlist.');
        }
        return allowed;
      }).toList();

      if (eligibleSongs.isEmpty) {
        throw Exception(
            'No playable songs found (missing or invalid audio URLs).');
      }

      late final BuiltQueue built;
      try {
        built = QueueBuilder.build(
          songs: eligibleSongs,
          startIndex: startIndex,
          locallyAvailableSongIds: localPaths.keys.toSet(),
          windowSize: _maxQueueWindow,
        );
      } on StateError {
        throw Exception(
            'No playable songs found (missing or invalid audio URLs).');
      }

      _playlist = built.songs;
      _currentIndex = built.startIndex;

      final audioSources = <AudioSource>[];
      for (final song in _playlist) {
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.singerName ?? 'Mewati Artist',
          artUri: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
              ? Uri.tryParse(song.coverImageUrl!)
              : null,
        );

        final localPath = localPaths[song.id];
        if (localPath != null) {
          audioSources.add(
            AudioSource.uri(Uri.file(localPath), tag: mediaItem),
          );
        } else {
          audioSources.add(
            AudioSource.uri(Uri.parse(song.audioUrl), tag: mediaItem),
          );
        }
      }

      final playlistSource = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlistSource, initialIndex: _currentIndex);
      await _player.setShuffleModeEnabled(_shuffleMode);

      await _ensureNotificationPermission();

      unawaited(_player.play().catchError((e) {
        debugPrint('PlayerService.play error: $e');
      }));
    } catch (e) {
      throw Exception('Failed to play playlist: ${e.toString()}');
    }
  }

  void _handleIndexChanged(Song song) {
    if (song.id == _playCountTrackedSongId) return;
    _playCountTrackedSongId = song.id;
    _startPlayCountTracking(song);
  }

  void _startPlayCountTracking(Song song) {
    _playCountTimer?.cancel();
    if (_playCountedSongIds.contains(song.id)) return;

    final trackedSongId = song.id;
    _playCountTimer = Timer(_playCountThreshold, () {
      if (_playCountTrackedSongId != trackedSongId) return;
      final state = _player.playerState;
      if (state.playing) {
        _playCountedSongIds.add(trackedSongId);
        _trackPlayCount(song);
      }
    });
  }

  void _trackPlayCount(Song song) {
    _songsService.incrementPlayCount(song.id);
  }

  Future<void> _initEqualizer() async {
    try {
      await EqualizerService().init();
      final prefs = await SharedPreferences.getInstance();
      final savedPreset = prefs.getString('eq_preset') ?? 'mewati-bass';
      await EqualizerService().applyPreset(savedPreset);
    } catch (e) {
      debugPrint("Equalizer init (player) Error: $e");
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      unawaited(_player.play().catchError((e) {
        debugPrint('PlayerService.togglePlayPause play error: $e');
      }));
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    await _player.seekToNext();
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
  }

  /// FIXED (Batch 3 audit — Drive Mode queue tap): jumps directly to
  /// `index` within the already-loaded ConcatenatingAudioSource instead of
  /// rebuilding/reloading the whole queue via setPlaylist(). Drive Mode's
  /// queue list uses this so tapping a row is an instant jump instead of a
  /// full playlist reload (re-resolving local paths, rebuilding the audio
  /// source, isLoading flicker, playback restarting from scratch).
  Future<void> jumpToQueueIndex(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) {
      unawaited(_player.play().catchError((e) {
        debugPrint('PlayerService.jumpToQueueIndex play error: $e');
      }));
    }
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
    _player.setShuffleModeEnabled(_shuffleMode);
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> fadeOut({Duration duration = const Duration(seconds: 30)}) async {
    cancelFadeOut();
    final token = ++_fadeToken;
    _originalVolume = _player.volume;
    final steps = max(1, duration.inMilliseconds ~/ 100);
    final volumeStep = _originalVolume / steps;
    int stepCount = 0;

    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (token != _fadeToken) {
        timer.cancel();
        return;
      }
      stepCount++;
      double newVolume = _originalVolume - (volumeStep * stepCount);
      if (newVolume <= 0.0) {
        timer.cancel();
        if (token == _fadeToken) {
          await _player.setVolume(0.0);
          await _player.pause();
          await _player.setVolume(_originalVolume);
        }
      } else {
        await _player.setVolume(newVolume);
      }
    });
  }

  void cancelFadeOut() {
    _fadeToken++;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _player.setVolume(_originalVolume);
  }

  void handleAppDetached() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  void dispose() {
    _fadeTimer?.cancel();
    _playCountTimer?.cancel();
    _internalIndexSubscription?.cancel();
    _player.dispose();
  }
}
