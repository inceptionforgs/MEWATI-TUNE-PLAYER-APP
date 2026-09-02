import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  }

  Future<void> setPlaylist({required List<Song> songs, required int startIndex}) async {
    try {
      final validSongs = songs.where((s) => s.audioUrl.trim().isNotEmpty).toList();
      if (validSongs.isEmpty) {
        throw Exception('No playable songs found (missing audio URLs).');
      }
      Song? requestedSong = (startIndex >= 0 && startIndex < songs.length) ? songs[startIndex] : null;
      int adjustedStartIndex = 0;
      if (requestedSong != null) {
        final foundIndex = validSongs.indexWhere((s) => s.id == requestedSong.id);
        if (foundIndex != -1) adjustedStartIndex = foundIndex;
      }
      _playlist = validSongs;
      _currentIndex = adjustedStartIndex;
      
      List<AudioSource> audioSources = [];
      for (final song in validSongs) {
        final mediaItem = MediaItem(
          id: song.id,
          title: song.title,
          artist: song.singerName ?? 'Mewati Artist',
          artUri: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
              ? Uri.tryParse(song.coverImageUrl!)
              : null,
        );

        try {
          bool isDownloaded = await _downloadsService.isSongDownloaded(song.id);
          String localPath = await _downloadsService.getLocalSongPath(song.id);
          
          if (isDownloaded && await File(localPath).exists()) {
            // Local file play
            audioSources.add(AudioSource.file(File(localPath), tag: mediaItem));
          } else {
            // 🔥 FIX: Direct URI - No LockCachingAudioSource
            audioSources.add(AudioSource.uri(Uri.parse(song.audioUrl), tag: mediaItem));
          }
        } catch (e) {
          // Agar kisi ek song ka source nahi bana, toh use skip karo
          debugPrint('⚠️ Skipping song ${song.id} due to error: $e');
          continue;
        }
      }

      if (audioSources.isEmpty) {
        throw Exception('No valid audio sources could be created.');
      }

      final playlistSource = ConcatenatingAudioSource(children: audioSources);
      await _player.setAudioSource(playlistSource, initialIndex: adjustedStartIndex);
      _initEqualizer();

      // Play automatically (catch errors)
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
    if (_shuffleMode && _playlist.length > 1) {
      int newIndex = _currentIndex;
      while (newIndex == _currentIndex) {
        newIndex = Random().nextInt(_playlist.length);
      }
      _currentIndex = newIndex;
    } else {
      if (_currentIndex < _playlist.length - 1) {
        _currentIndex++;
      } else if (_player.loopMode == LoopMode.all) {
        _currentIndex = 0;
      } else {
        await _player.pause();
        return;
      }
    }
    await _player.seek(Duration.zero, index: _currentIndex);
    unawaited(_player.play().catchError((e) {
      debugPrint('PlayerService.next play error: $e');
    }));
    _trackPlayCount(_playlist[_currentIndex]);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_shuffleMode && _playlist.length > 1) {
      int newIndex = _currentIndex;
      while (newIndex == _currentIndex) {
        newIndex = Random().nextInt(_playlist.length);
      }
      _currentIndex = newIndex;
    } else {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else if (_player.loopMode == LoopMode.all) {
        _currentIndex = _playlist.length - 1;
      } else {
        await _player.seek(Duration.zero);
        return;
      }
    }
    await _player.seek(Duration.zero, index: _currentIndex);
    unawaited(_player.play().catchError((e) {
      debugPrint('PlayerService.previous play error: $e');
    }));
    _trackPlayCount(_playlist[_currentIndex]);
  }

  void toggleShuffle() {
    _shuffleMode = !_shuffleMode;
  }

  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> fadeOut({Duration duration = const Duration(seconds: 30)}) async {
    _fadeTimer?.cancel();
    _originalVolume = _player.volume;
    final steps = duration.inMilliseconds ~/ 100;
    final volumeStep = _originalVolume / steps;
    int stepCount = 0;

    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      stepCount++;
      double newVolume = _originalVolume - (volumeStep * stepCount);
      if (newVolume <= 0.0) {
        timer.cancel();
        await _player.setVolume(0.0);
        await _player.pause();
        await _player.setVolume(_originalVolume);
      } else {
        await _player.setVolume(newVolume);
      }
    });
  }

  void cancelFadeOut() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _player.setVolume(_originalVolume);
  }

  void dispose() {
    _fadeTimer?.cancel();
    _player.dispose();
  }
}