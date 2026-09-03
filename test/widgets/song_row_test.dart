import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/core/widgets/song_row.dart';
import 'package:mewati_tune_player/models/song.dart';

/// Minimal stand-in for AppThemeData — SongRow only reads a handful of
/// color fields off `t` (typed `dynamic` in the widget).
class _FakeTheme {
  final Color surface = Colors.grey;
  final Color textPrimary = Colors.white;
  final Color accent = Colors.deepOrange;
  final Color background = Colors.black;
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  final song = Song(
    id: 's1',
    title: 'Test Song',
    audioUrl: 'https://example.com/a.mp3',
    // coverImageUrl intentionally left null so the widget renders a plain
    // Icon instead of attempting a real network image fetch in tests.
  );

  testWidgets('shows the action icons alongside the NOW badge when isNow is true', (tester) async {
    await tester.pumpWidget(_wrap(SongRow(
      t: _FakeTheme(),
      data: SongRowData(
        song: song,
        isNow: true,
        isPlaying: true,
        isFav: false,
        isDownloaded: false,
        isDownloading: false,
        progress: 0,
        isLiked: false,
        likeCount: 3,
      ),
      actions: SongRowActions(
        onTap: () {},
        onToggleFavorite: () {},
        onDownload: () {},
        onCancelDownload: () {},
        onRemoveDownload: () {},
        onToggleLike: () {},
      ),
    )));

    // NOW badge is present...
    expect(find.text('Ⅱ NOW'), findsOneWidget);
    // ...alongside the action icons, not instead of them.
    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });

  testWidgets('reflects liked/favorited/downloaded state via icon and color choice', (tester) async {
    await tester.pumpWidget(_wrap(SongRow(
      t: _FakeTheme(),
      data: SongRowData(
        song: song,
        isNow: false,
        isPlaying: false,
        isFav: true,
        isDownloaded: true,
        isDownloading: false,
        progress: 0,
        isLiked: true,
        likeCount: 5,
      ),
      actions: SongRowActions(
        onTap: () {},
        onToggleFavorite: () {},
        onDownload: () {},
        onCancelDownload: () {},
        onRemoveDownload: () {},
        onToggleLike: () {},
      ),
    )));

    expect(find.text('Ⅱ NOW'), findsNothing);
    expect(find.byIcon(Icons.thumb_up), findsOneWidget); // liked (filled)
    expect(find.byIcon(Icons.favorite), findsOneWidget); // favorited (filled)
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // downloaded
  });

  testWidgets('tapping the like button invokes onToggleLike', (tester) async {
    var toggled = false;
    await tester.pumpWidget(_wrap(SongRow(
      t: _FakeTheme(),
      data: SongRowData(
        song: song,
        isNow: false,
        isPlaying: false,
        isFav: false,
        isDownloaded: false,
        isDownloading: false,
        progress: 0,
        isLiked: false,
        likeCount: 0,
      ),
      actions: SongRowActions(
        onTap: () {},
        onToggleFavorite: () {},
        onDownload: () {},
        onCancelDownload: () {},
        onRemoveDownload: () {},
        onToggleLike: () => toggled = true,
      ),
    )));

    await tester.tap(find.byIcon(Icons.thumb_up_outlined));
    expect(toggled, isTrue);
  });
}
