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
    return Singer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Singer',
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      songCount: json['song_count'] as int? ?? json['songs_count'] as int?,
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