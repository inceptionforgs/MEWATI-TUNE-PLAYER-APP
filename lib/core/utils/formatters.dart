String formatCount(int count) {
  if (count < 1000) return count.toString();
  if (count < 1000000) {
    final value = count / 1000;
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)}K';
  }
  if (count < 1000000000) {
    final value = count / 1000000;
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)}M';
  }
  final value = count / 1000000000;
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)}B';
}