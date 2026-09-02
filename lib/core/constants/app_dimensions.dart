class AppDimensions {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 12.0;
  static const double paddingL = 16.0;
  static const double paddingXL = 20.0;
  static const double paddingXXL = 24.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;

  static const double tabHeight = 53.0;
  // Fix: MiniPlayerBar (title + slider + buttons) actually renders at
  // ~172px, not 64px — the old value caused the last rows of every list
  // to be covered/untappable behind the mini-player.
  static const double miniPlayerHeight = 172.0;

  static const double albumArtSize = 230.0;
  static const double avatarSize = 54.0;
  static const double smallAvatarSize = 28.0;
}
