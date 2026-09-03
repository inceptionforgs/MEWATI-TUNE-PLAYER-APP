class Song {
  final String id;
  final String title;
  final String? singerId;
  final String? singerName;
  final String? category;
  final String audioUrl;
  final String? coverImageUrl;
  final int? duration;
  final int playCount;
  final int likeCount;
  final bool isPremium;

  Song({
    required this.id,
    required this.title,
    this.singerId,
    this.singerName,
    this.category,
    required this.audioUrl,
    this.coverImageUrl,
    this.duration,
    this.playCount = 0,
    this.likeCount = 0,
    this.isPremium = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    String? singerName;
    if (json['singers'] != null && json['singers'] is Map<String, dynamic>) {
      final singersMap = json['singers'] as Map<String, dynamic>;
      singerName = singersMap['name'] as String?;
    } else if (json['singer_name'] != null) {
      singerName = json['singer_name'] as String?;
    }

    // Helper to safely convert int? from num or String.
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    int parseIntWithDefault(dynamic value, int defaultValue) {
      return parseInt(value) ?? defaultValue;
    }

    // Fix (File 27): robust bool parser — Supabase can send 0/1 (or even
    // "true"/"false" strings) instead of a real boolean, and a direct
    // `json['is_premium'] as bool?` cast would throw on those, silently
    // dropping the row or crashing the mapping.
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final v = value.toLowerCase().trim();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
      }
      return defaultValue;
    }

    return Song(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown Song',
      singerId: json['singer_id'] as String?,
      singerName: singerName,
      category: json['category'] as String?,
      audioUrl: json['audio_url'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      duration: parseInt(json['duration']),
      playCount: parseIntWithDefault(json['play_count'], 0),
      likeCount: parseIntWithDefault(json['like_count'], 0),
      isPremium: parseBool(json['is_premium'], false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'singer_id': singerId,
      'singer_name': singerName,
      'category': category,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'play_count': playCount,
      'like_count': likeCount,
      'is_premium': isPremium,
    };
  }

  /// Maps raw Supabase rows to [Song]s, skipping (not throwing on) any row
  /// with a missing id or empty/invalid audioUrl.
  ///
  /// Fixed (Serial 17): moved here from SongsService._mapSongs so this
  /// validation/skip logic can be unit tested directly without a network
  /// call — Dart privacy is per-file, so the old private method could
  /// never be tested on its own. Behavior is unchanged: a bad row is still
  /// skipped, never thrown. (The per-row debugPrint logging that used to
  /// live alongside this in SongsService was dropped since this file has
  /// no Flutter dependency by design — the skip behavior itself, which is
  /// what matters functionally, is identical.)
  static List<Song> mapValidRows(List<dynamic> rows) {
    final songs = <Song>[];
    for (final item in rows) {
      try {
        final map = item as Map<String, dynamic>;
        final id = map['id'] as String? ?? '';
        final audioUrl = map['audio_url'] as String? ?? '';
        if (id.isEmpty || audioUrl.trim().isEmpty) {
          continue;
        }
        songs.add(Song.fromJson(map));
      } catch (_) {
        // Skip any row that fails to parse instead of throwing.
      }
    }
    return songs;
  }
}
