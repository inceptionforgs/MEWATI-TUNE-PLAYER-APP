// FILE: lib/core/utils/queue_builder.dart
import '../../models/song.dart';

/// Result of building a validated, windowed playback queue.
class BuiltQueue {
  final List<Song> songs;
  final int startIndex;

  const BuiltQueue({required this.songs, required this.startIndex});
}

/// Pure (no I/O, no platform channels) logic for validating and windowing
/// a playback queue.
///
/// Fixed (Serial 17): this was previously inlined directly inside
/// PlayerService.setPlaylist, which made it impossible to unit test without
/// a real AudioPlayer / SharedPreferences / file system (all of which need
/// platform channels). Moving it here — with the same behavior, just a new
/// location — lets it be covered by real unit tests. PlayerService still
/// owns the async "is this song downloaded on disk" check and passes the
/// resulting verified ids in via [locallyAvailableSongIds].
class QueueBuilder {
  /// Cap on how many songs are ever loaded into a single queue at once, to
  /// avoid OOM on large libraries. Window is centered on the requested
  /// start index. Kept in sync with PlayerService's internal window size.
  static const int maxQueueWindow = 60;

  /// Filters [songs] down to ones with a playable source, remaps
  /// [startIndex] into the filtered list, and caps the result to a window
  /// of at most [windowSize] songs centered on the (remapped) start index.
  ///
  /// A song is considered playable if either:
  ///  - its id is present in [locallyAvailableSongIds] (a verified local
  ///    download), OR
  ///  - its audioUrl parses to a URI with a non-empty host.
  ///
  /// Throws [ArgumentError] if [songs] is empty, or [StateError] if every
  /// song is unplayable — PlayerService.setPlaylist catches both and wraps
  /// them into its usual user-facing Exception, matching prior behavior.
  static BuiltQueue build({
    required List<Song> songs,
    required int startIndex,
    Set<String> locallyAvailableSongIds = const {},
    int windowSize = maxQueueWindow,
  }) {
    if (songs.isEmpty) {
      throw ArgumentError('Playlist is empty.');
    }

    final validSongs = <Song>[];
    for (final song in songs) {
      final hasValidLocalFile = locallyAvailableSongIds.contains(song.id);
      final uri = Uri.tryParse(song.audioUrl);
      final hasValidRemote = uri != null && uri.host.isNotEmpty;

      if (!hasValidLocalFile && !hasValidRemote) {
        continue;
      }
      validSongs.add(song);
    }

    if (validSongs.isEmpty) {
      throw StateError(
          'No playable songs found (missing or invalid audio URLs).');
    }

    int adjustedStart = 0;
    if (startIndex >= 0 && startIndex < songs.length) {
      final requested = songs[startIndex];
      final found = validSongs.indexWhere((s) => s.id == requested.id);
      if (found != -1) {
        adjustedStart = found;
      }
    }

    List<Song> queueSongs = validSongs;
    int queueStartIndex = adjustedStart;
    if (validSongs.length > windowSize) {
      final half = windowSize ~/ 2;
      int lo = (adjustedStart - half).clamp(0, validSongs.length - 1);
      int hi = (lo + windowSize).clamp(0, validSongs.length);
      lo = (hi - windowSize).clamp(0, validSongs.length);
      queueSongs = validSongs.sublist(lo, hi);
      queueStartIndex = adjustedStart - lo;
    }

    return BuiltQueue(songs: queueSongs, startIndex: queueStartIndex);
  }
}
