class Singer {
  final String id;
  final String name;
  final String? bio;
  final String? photoUrl;
  final int? songCount;

  Singer({
    required this.id,
    required this.name,
    this.bio,
    this.photoUrl,
    this.songCount,
  });

  factory Singer.fromJson(Map<String, dynamic> json) {
    // Fix: same robust-parsing pattern as File 27's is_premium fix —
    // song_count may come back as bigint/num from Supabase, and a direct
    // `as int?` cast throws on that instead of just parsing it.
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Singer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Singer',
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      songCount: parseInt(json['song_count']) ?? parseInt(json['songs_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'photo_url': photoUrl,
      'song_count': songCount,
    };
  }
}
