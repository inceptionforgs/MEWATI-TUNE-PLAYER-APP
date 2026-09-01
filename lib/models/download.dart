class Download {
  final String userId;
  final String songId;
  final String? localFilePath;

  Download({
    required this.userId,
    required this.songId,
    this.localFilePath,
  });

  factory Download.fromJson(Map<String, dynamic> json) {
    return Download(
      userId: json['user_id'] as String? ?? '',
      songId: json['song_id'] as String? ?? '',
      localFilePath: json['local_file_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'song_id': songId,
      'local_file_path': localFilePath,
    };
  }
}