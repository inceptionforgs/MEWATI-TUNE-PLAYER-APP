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

  final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [
        EqualizerService().equalizer,
        EqualizerService().loudnessEnhancer,
      ],
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
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _playlist.length) {
        _currentIndex = index;
      }
    });
    _initEqualizer();
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

      final validSongs = <Song>[];
      for (final song in songs) {
        final uri = Uri.tryParse(song.audioUrl);
        if (uri == null || uri.host.isEmpty) {
          debugPrint('PlayerService: skipping song with bad URL: ${song.title}');
          continue;
        }
        validSongs.add(song);
      }

      if (validSongs.isEmpty) {
        throw Exception('No playable songs found (missing or invalid audio URLs).');
      }

      int adjustedStart = 0;
      if (startIndex >= 0 && startIndex < songs.length) {
        final requested = songs[startIndex];
        final found = validSongs.indexWhere((s) => s.id == requested.id);
        if (found != -1) {
          adjustedStart = found;
        }
      }

      _playlist = validSongs;
      _currentIndex = adjustedStart;

      final audioSources = <AudioSource>[];
      for (final song in validSongs) {
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.singerName ?? 'Mewati Artist',
          artUri: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
              ? Uri.tryParse(song.coverImageUrl!)
              : null,
        );

        if (downloadedIds.contains(song.id)) {
          final localPath = await _downloadsService.getLocalSongPath(
            song.id,
            audioUrl: song.audioUrl,
          );
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
      await _player.setAudioSource(playlistSource, initialIndex: adjustedStart);
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

  Future<void> playSong(Song song) async {
    await setPlaylist(songs: [song], startIndex: 0);
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

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    await _player.seekToNext();
    if (_player.playing) {
      _trackPlayCount(_playlist[_currentIndex]);
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
      _trackPlayCount(_playlist[_currentIndex]);
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

  void dispose() {
    _fadeTimer?.cancel();
    _player.dispose();
  }
}