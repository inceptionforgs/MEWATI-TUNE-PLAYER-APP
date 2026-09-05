// File: lib/screens/player/widgets/album_art.dart
//
// Added per-theme corner radius to match the prototype's --thumb-radius
// token (Walkman Orange: 12, Deep Black/cyber: 0 — sharp square, Apple
// Green/silver-chrome: 8). Everything else (gradient, border, shadow,
// cached image loading) is unchanged.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_themes.dart';
import '../../../core/constants/themes/app_theme_id.dart';
import '../../../models/song.dart';
import '../../../services/app_cache_manager.dart';

class AlbumArt extends StatelessWidget {
  final Song song;
  final AppThemeData t;

  const AlbumArt({Key? key, required this.song, required this.t}) : super(key: key);

  static double _radius(AppThemeId id) {
    switch (id) {
      case AppThemeId.cyberBlack:
        return 0;
      case AppThemeId.silverChrome:
        return 8;
      default:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = _radius(t.id);

    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        // Theme-derived gradient (fixed in File 42) instead of a hardcoded
        // pair of colors that never changed with the active theme.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.surface, t.background],
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
              borderRadius: BorderRadius.circular(radius > 2 ? radius - 2 : 0),
              child: CachedNetworkImage(
                imageUrl: song.coverImageUrl!,
                fit: BoxFit.cover,
                cacheManager: AppCacheManager.instance,
                memCacheWidth: 512,
                memCacheHeight: 512,
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
