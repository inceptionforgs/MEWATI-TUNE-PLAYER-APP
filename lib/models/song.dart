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
      isPremium: json['is_premium'] as bool? ?? false,
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
}