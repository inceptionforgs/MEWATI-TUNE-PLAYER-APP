// File: lib/screens/player/widgets/album_art.dart
//
// Per-theme corner radius matching the prototype's --thumb-radius token
// (Walkman Orange: 12, Deep Black/cyber: 0 — sharp square, Apple
// Green/silver-chrome: 8).
//
// FIXED (Batch 3 audit): was a hardcoded 230x230 regardless of screen
// size — the single biggest contributor to Now Playing's small-screen
// overflow. AppDimensions.albumArtSize now acts as a *maximum*; on
// screens narrower than that it shrinks to fit instead of forcing the
// fixed size no matter what.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_themes.dart';
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

    // FIXED: responsive size instead of a hardcoded 230. Caps at
    // AppDimensions.albumArtSize on normal/large screens, but shrinks on
    // narrow ones (small Android phones, iPhone SE) so it — plus the
    // horizontal margins around it — never forces the Now Playing column
    // past the available height.
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth < AppDimensions.albumArtSize + 90
        ? screenWidth - 90
        : AppDimensions.albumArtSize;

    return Container(
      width: size,
      height: size,
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

