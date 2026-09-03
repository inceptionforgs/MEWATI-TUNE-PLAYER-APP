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

  // Use EqualizerService's guarded androidAudioEffects getter instead of
  // passing its (now nullable) equalizer/loudnessEnhancer fields directly.
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

  // Store the internal subscription so it can actually be cancelled
  // instead of leaking for the app's lifetime.
  StreamSubscription<int?>? _internalIndexSubscription;

  // Play-count tracking is now reactive, driven off currentIndexStream,
  // instead of being called directly right after seek/play calls (which
  // could read a stale _currentIndex/currentSong before the stream had
  // actually updated it). See _handleIndexChanged / _startPlayCountTracking.
  String? _playCountTrackedSongId;
  Timer? _playCountTimer;
  final Set<String> _playCountedSongIds = {};
  static const Duration _playCountThreshold = Duration(seconds: 25);

  // POST_NOTIFICATIONS (Android 13+) is requested the first time playback
  // actually starts, not at app bootstrap. Guarded so it only ever asks
  // once per app run.
  static bool _notificationPermissionRequested = false;

  // Readiness gate so play() never races JustAudioBackground.init().
  // main.dart (File 5) must call PlayerService.markReady() once init
  // has actually finished.
  static bool _backgroundReady = false;
  static void markReady() => _backgroundReady = true;

  // Cap on how many AudioSource children we ever load into a single
  // ConcatenatingAudioSource at once, to avoid OOM on large libraries.
  // Window is centered on the requested start index. Kept in sync with
  // QueueBuilder.maxQueueWindow (Serial 17).
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

  /// Waits (briefly) for JustAudioBackground init to have completed before
  /// allowing playback to start. main.dart now awaits the init sequence
  /// before runApp (File 5), so this should return immediately in the
  /// normal case — this is a defensive guard, not the primary fix.
  Future<void> ensureReady() async {
    if (_backgroundReady) return;
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!_backgroundReady && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Requests POST_NOTIFICATIONS (Android 13+) the first time playback is
  /// actually about to start. On older Android versions the permission is
  /// granted by default, and the underlying plugin call is a no-op there.
  /// Guarded by [_notificationPermissionRequested] so this only ever runs
  /// once per app run, no matter how many times setPlaylist is called.
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

      // Downloaded-file check runs first and actually verifies the file
      // on disk (existsSync + length > 0) instead of trusting the id list
      // blindly. Only songs with a VERIFIED local file are passed to
      // QueueBuilder as "locally available" — everything else is judged
      // purely on its remote URL there.
      final localPaths = <String, String>{}; // song.id -> verified local path

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
            // Stale/corrupt download id — drop it silently here and fall
            // back to streaming, rather than failing the whole playlist.
            debugPrint(
                'PlayerService: downloaded file missing/corrupt for "${song.title}", falling back to stream.');
          }
        }
      }

      // Host allowlist: a song is only eligible to stream remotely if its
      // audioUrl's host matches the project's CDN allowlist. Songs with a
      // verified local file (above) bypass this, since they don't hit the
      // network at all. Anything else that fails the check is dropped
      // here — the same "skip, don't fail the whole playlist" treatment
      // used for corrupt local files above.
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

      // Fixed (Serial 17): validation + windowing logic moved to
      // QueueBuilder (lib/core/utils/queue_builder.dart) so it can be unit
      // tested without a real AudioPlayer/SharedPreferences/file system.
      // Behavior is unchanged from the original inline version.
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

      // First-play notification permission request (Item 5): guarded, only
      // ever runs once, and happens right before the first real play()
      // call rather than at app bootstrap.
      await _ensureNotificationPermission();

      unawaited(_player.play().catchError((e) {
        debugPrint('PlayerService.play error: $e');
      }));

      // Play-count tracking for the initial song is now handled reactively
      // by the currentIndexStream listener (_handleIndexChanged), which
      // fires once setAudioSource actually reports the current index —
      // avoids counting a play before the index stream has caught up.
    } catch (e) {
      throw Exception('Failed to play playlist: ${e.toString()}');
    }
  }

  /// Called whenever currentIndexStream emits a valid index. Only acts
  /// when the song has actually changed (avoids restarting the timer or
  /// double-counting if the stream fires again for the same song/index).
  void _handleIndexChanged(Song song) {
    if (song.id == _playCountTrackedSongId) return;
    _playCountTrackedSongId = song.id;
    _startPlayCountTracking(song);
  }

  /// Waits ~25s (within the 20-30s window) then, if we're still on the
  /// same song and the player is actively playing (not in an error
  /// state), counts one play for it. Counted at most once per song per
  /// app session.
  void _startPlayCountTracking(Song song) {
    _playCountTimer?.cancel();
    if (_playCountedSongIds.contains(song.id)) return;

    final trackedSongId = song.id;
    _playCountTimer = Timer(_playCountThreshold, () {
      if (_playCountTrackedSongId != trackedSongId) return;
      final state = _player.playerState;
      if (state.playing && state.processingState != ProcessingState.error) {
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

  // SleepTimerService calls pause() on PlayerService, which didn't exist
  // and crashed the app when a sleep timer ended.
  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    await _player.seekToNext();
    // Play-count tracking is handled reactively by _handleIndexChanged
    // once currentIndexStream actually reports the new index.
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
    // Play-count tracking is handled reactively by _handleIndexChanged
    // once currentIndexStream actually reports the new index.
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

  /// Call this from the app's lifecycle observer when
  /// AppLifecycleState.detached fires (app is being fully terminated) —
  /// NOT on a normal route pop. Only cancels the fade timer; the actual
  /// AudioPlayer singleton is intentionally left alone here so background
  /// playback isn't interrupted by a simple lifecycle transition.
  void handleAppDetached() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  /// Full teardown — only call this when the singleton itself must be
  /// destroyed (e.g. app process is actually shutting down for good).
  /// Do NOT call this on a normal route pop or screen dispose.
  void dispose() {
    _fadeTimer?.cancel();
    _playCountTimer?.cancel();
    _internalIndexSubscription?.cancel();
    _player.dispose();
  }
}
