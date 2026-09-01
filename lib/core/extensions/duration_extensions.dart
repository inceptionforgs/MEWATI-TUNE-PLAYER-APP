extension DurationExtensions on Duration {
  String get asMinutesSeconds {
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get asHoursMinutesSeconds {
    final h = inHours.toString().padLeft(2, '0');
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get asCompact {
    if (inHours > 0) return asHoursMinutesSeconds;
    return asMinutesSeconds;
  }
}