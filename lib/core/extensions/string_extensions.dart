extension StringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  String orDefault(String fallback) => isNullOrEmpty ? fallback : this!;

  String capitalize() {
    if (isNullOrEmpty) return '';
    return this![0].toUpperCase() + this!.substring(1);
  }

  String titleCase() {
    if (isNullOrEmpty) return '';
    return this!.split(' ').map((word) => word.capitalize()).join(' ');
  }

  String initials({int count = 2}) {
    if (isNullOrEmpty) return '';
    final parts = this!.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length && i < count; i++) {
      buffer.write(parts[i][0].toUpperCase());
    }
    return buffer.toString();
  }
}