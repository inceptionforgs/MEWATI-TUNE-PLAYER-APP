import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_themes.dart';
import '../../../models/song.dart';

class AlbumArt extends StatelessWidget {
  final Song song;
  final AppThemeData t;

  const AlbumArt({Key? key, required this.song, required this.t}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A170D), Color(0xFF120C08)],
        ),
        border: Border.all(
          color: t.textPrimary.withOpacity(0.28),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 45,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: (song.coverImageUrl != null && song.coverImageUrl!.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: song.coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Icon(Icons.music_note, color: t.textPrimary, size: 64),
                errorWidget: (context, url, error) =>
                    Icon(Icons.music_note, color: t.textPrimary, size: 64),
              ),
            )
          : Icon(
              Icons.music_note,
              color: t.textPrimary.withOpacity(0.85),
              size: 64,
            ),
    );
  }
}