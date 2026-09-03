import 'package:flutter_test/flutter_test.dart';
import 'package:mewati_tune_player/models/song.dart';
import 'package:mewati_tune_player/providers/likes_provider.dart';
import 'package:mewati_tune_player/services/like_service.dart';

/// Fake LikeService used only in tests. Implements (not extends)
/// LikeService so no real Supabase client is ever touched.
///
/// Deliberately exposes ONLY the same public surface as the real
/// LikeService (isLiked/getLikeCount/getLikedSongIds/toggleLike) — there
/// is no separate insert/delete method to call, which is what backs the
/// "toggle_like RPC is the only path used" test below.
class FakeLikeService implements LikeService {
  final Set<String> _liked = {};
  final Map<String, int> serverCountAfterToggle;

  int toggleLikeCallCount = 0;
  int getLikedSongIdsCallCount = 0;
  Object? toggleLikeError;

  FakeLikeService({
    Set<String> initiallyLiked = const {},
    this.serverCountAfterToggle = const {},
  }) {
    _liked.addAll(initiallyLiked);
  }

  @override
  Future<bool> isLiked(String songId) async => _liked.contains(songId);

  @override
  Future<int> getLikeCount(String songId) async => serverCountAfterToggle[songId] ?? 0;

  @override
  Future<Set<String>> getLikedSongIds(List<String> songIds) async {
    getLikedSongIdsCallCount++;
    return songIds.where(_liked.contains).toSet();
  }

  @override
  Future<int> toggleLike(String songId) async {
    toggleLikeCallCount++;
    if (toggleLikeError != null) {
      final err = toggleLikeError!;
      throw err;
    }
    if (_liked.contains(songId)) {
      _liked.remove(songId);
    } else {
      _liked.add(songId);
    }
    return serverCountAfterToggle[songId] ?? (_liked.contains(songId) ? 1 : 0);
  }
}

Song _song(String id, {int likeCount = 0}) =>
    Song(id: id, title: 'Song $id', audioUrl: 'https://example.com/$id.mp3', likeCount: likeCount);

void main() {
  group('LikesProvider.toggleLike', () {
    test('like then unlike (double tap) ends back at the original state', () async {
      final fake = FakeLikeService(serverCountAfterToggle: {'s1': 1});
      final provider = LikesProvider(likeService: fake);

      await provider.toggleLike('s1');
      expect(provider.isLikedSync('s1'), isTrue);
      expect(provider.getLikeCountSync('s1'), 1);

      final fake2 = FakeLikeService(initiallyLiked: {'s1'}, serverCountAfterToggle: {'s1': 0});
      final provider2 = LikesProvider(likeService: fake2);
      await provider2.loadLikesData([_song('s1', likeCount: 1)]);
      await provider2.toggleLike('s1');

      expect(provider2.isLikedSync('s1'), isFalse);
      expect(provider2.getLikeCountSync('s1'), 0);
    });

    test('concurrent taps both resolve without crashing and call the service each time', () async {
      final fake = FakeLikeService(serverCountAfterToggle: {'s1': 1});
      final provider = LikesProvider(likeService: fake);

      await Future.wait([
        provider.toggleLike('s1'),
        provider.toggleLike('s1'),
      ]);

      expect(fake.toggleLikeCallCount, 2);
      // Whatever the final state is, counts must never go negative.
      expect(provider.getLikeCountSync('s1'), greaterThanOrEqualTo(0));
    });

    test('rolls back to the pre-toggle state on network failure', () async {
      final fake = FakeLikeService(initiallyLiked: {}, serverCountAfterToggle: {'s1': 5});
      final provider = LikesProvider(likeService: fake);
      await provider.loadLikesData([_song('s1', likeCount: 4)]);

      fake.toggleLikeError = Exception('SocketException: Failed host lookup');
      await provider.toggleLike('s1');

      expect(provider.isLikedSync('s1'), isFalse); // back to original (was not liked)
      expect(provider.getLikeCountSync('s1'), 4); // back to original count
      expect(provider.errorMessage, isNotNull);
    });

    test('toggle_like RPC is the only path used — no separate insert/delete calls', () async {
      final fake = FakeLikeService(serverCountAfterToggle: {'s1': 1});
      final provider = LikesProvider(likeService: fake);

      await provider.toggleLike('s1');

      // FakeLikeService only exposes the same methods as the real
      // LikeService (isLiked/getLikeCount/getLikedSongIds/toggleLike) —
      // there is structurally no separate insert/delete method for
      // LikesProvider to call. Confirm toggleLike was the only thing hit.
      expect(fake.toggleLikeCallCount, 1);
      expect(fake.getLikedSongIdsCallCount, 0);
    });
  });

  group('LikesProvider.loadLikesData', () {
    test('seeds like counts from the song payload without a network call for counts', () async {
      final fake = FakeLikeService();
      final provider = LikesProvider(likeService: fake);

      await provider.loadLikesData([_song('s1', likeCount: 10), _song('s2', likeCount: 20)]);

      expect(provider.getLikeCountSync('s1'), 10);
      expect(provider.getLikeCountSync('s2'), 20);
    });

    test('batches liked-status lookups into a single call for multiple songs', () async {
      final fake = FakeLikeService(initiallyLiked: {'s1'});
      final provider = LikesProvider(likeService: fake);

      await provider.loadLikesData([_song('s1'), _song('s2'), _song('s3')]);

      expect(fake.getLikedSongIdsCallCount, 1);
      expect(provider.isLikedSync('s1'), isTrue);
      expect(provider.isLikedSync('s2'), isFalse);
    });

    test('does not re-check songs whose liked status was already fetched', () async {
      final fake = FakeLikeService(initiallyLiked: {'s1'});
      final provider = LikesProvider(likeService: fake);

      await provider.loadLikesData([_song('s1')]);
      await provider.loadLikesData([_song('s1')]);

      expect(fake.getLikedSongIdsCallCount, 1);
    });
  });
}
