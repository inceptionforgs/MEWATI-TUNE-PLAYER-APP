import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
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

  // Readiness gate so play() never races JustAudioBackground.init().
  // main.dart (File 5) must call PlayerService.markReady() once init
  // has actually finished.
  static bool _backgroundReady = false;
  static void markReady() => _backgroundReady = true;

  // Cap on how many AudioSource children we ever load into a single
  // ConcatenatingAudioSource at once, to avoid OOM on large libraries.
  // Window is centered on the requested start index.
  static const int _maxQueueWindow = 60;

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

      // Downloaded-file check now runs FIRST and actually verifies the
      // file on disk (existsSync + length > 0) instead of trusting the
      // id list blindly. A song is only skipped if it has NEITHER a
      // valid local file NOR a valid remote URL — previously a good
      // downloaded song could be dropped just because its remote URL
      // happened to be bad, since the URL check ran first.
      final validSongs = <Song>[];
      final localPaths = <String, String>{}; // song.id -> verified local path

      for (final song in songs) {
        bool hasValidLocalFile = false;

        if (downloadedIds.contains(song.id)) {
          final candidatePath = await _downloadsService.getLocalSongPath(
            song.id,
            audioUrl: song.audioUrl,
          );
          final file = File(candidatePath);
          if (file.existsSync() && file.lengthSync() > 0) {
            hasValidLocalFile = true;
            localPaths[song.id] = candidatePath;
          } else {
            // Stale/corrupt download id — drop it silently here and fall
            // back to streaming, rather than failing the whole playlist.
            debugPrint(
                'PlayerService: downloaded file missing/corrupt for "${song.title}", falling back to stream.');
          }
        }

        final uri = Uri.tryParse(song.audioUrl);
        final hasValidRemote = uri != null && uri.host.isNotEmpty;

        if (!hasValidLocalFile && !hasValidRemote) {
          debugPrint('PlayerService: skipping song with no valid source: ${song.title}');
          continue;
        }

        validSongs.add(song);
      }

      if (validSongs.isEmpty) {
        throw Exception('No playable songs found (missing or invalid audio URLs).');
      }

      // Do not touch: startIndex is still remapped via indexWhere on song
      // id after filtering, same pattern as before.
      int adjustedStart = 0;
      if (startIndex >= 0 && startIndex < songs.length) {
        final requested = songs[startIndex];
        final found = validSongs.indexWhere((s) => s.id == requested.id);
        if (found != -1) {
          adjustedStart = found;
        }
      }

      // Cap the queue to a window around the current index instead of
      // loading the entire (possibly huge) library into one
      // ConcatenatingAudioSource, which risks OOM on large libraries.
      List<Song> queueSongs = validSongs;
      int queueStartIndex = adjustedStart;
      if (validSongs.length > _maxQueueWindow) {
        final half = _maxQueueWindow ~/ 2;
        int lo = (adjustedStart - half).clamp(0, validSongs.length - 1);
        int hi = (lo + _maxQueueWindow).clamp(0, validSongs.length);
        lo = (hi - _maxQueueWindow).clamp(0, validSongs.length);
        queueSongs = validSongs.sublist(lo, hi);
        queueStartIndex = adjustedStart - lo;
      }

      _playlist = queueSongs;
      _currentIndex = queueStartIndex;

      final audioSources = <AudioSource>[];
      for (final song in queueSongs) {
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
      await _player.setAudioSource(playlistSource, initialIndex: queueStartIndex);
      await _player.setShuffleModeEnabled(_shuffleMode);

      unawaited(_player.play().catchError((e) {
        debugPrint('PlayerService.play error: $e');
      }));

      _trackPlayCount(_playlist[_currentIndex]);
    } catch (e) {
      throw Exception('Failed to play playlist: ${e.toString()}');
    }
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

  // Dead code removed. Nothing outside this class called playSong(Song)
  // anymore — every screen already builds a real queue via
  // setPlaylist(songs:, startIndex:).

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
    if (_player.playing) {
      _trackPlayCount(currentSong ?? _playlist[_currentIndex]);
    }
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    await _player.seekToPrevious();
    if (_player.playing) {
      _trackPlayCount(currentSong ?? _playlist[_currentIndex]);
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
    final steps = duration.inMilliseconds ~/ 100;
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
    _internalIndexSubscription?.cancel();
    _player.dispose();
  }
}
