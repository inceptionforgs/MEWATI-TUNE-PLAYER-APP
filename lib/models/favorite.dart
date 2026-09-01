class Favorite {
  final String userId;
  final String songId;

  Favorite({
    required this.userId,
    required this.songId,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      userId: json['user_id'] as String? ?? '',
      songId: json['song_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'song_id': songId,
    };
  }
}