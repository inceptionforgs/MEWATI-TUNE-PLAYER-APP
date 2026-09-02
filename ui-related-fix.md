# Mewati Tune Player — Consolidated Fix List

*Compiled from three independent code audits (Claude, GPT, Grok) of the full source (parts 1–5). Deduplicated and prioritized.*

---

## 🔴 P0 — Critical (user-facing functional bugs, fix first)

1. **Playback queue breaks everywhere except Songs tab**
   `PlayerService.playSong()` always calls `setPlaylist(songs: [song], startIndex: 0)`. Trending, Favorites, Downloads, Search, and Singer Profile all call `playSong()` instead of `setPlaylist(fullList, index)`. Next/Previous/Shuffle become dead after playing from any of these screens.
   → Fix: replace `playSong(song)` calls in those screens with `setPlaylist(songs: currentList, startIndex: index)`.

2. **Persistent mini player disappears on pushed routes**
   `MiniPlayerBar` only lives inside `HomeScreen`. On Singer Profile or Search (pushed via `Navigator`/`MaterialPageRoute`), the mini player vanishes — no pause/skip control until the user backs out.
   → Fix: move `MiniPlayerBar` into `MaterialApp.builder` (next to `DebugPanel`) so it persists above the navigator.

3. **Currently-playing song can never be liked**
   `SongRow` hides like/favorite/download icons behind a "NOW" badge when `isNow` is true. `NowPlayingActions` (used on the Now Playing screen) has favorite/download/timer/equalizer buttons but no like button at all.
   → Fix: show icons alongside the NOW badge in `SongRow`; add a like button to `NowPlayingActions`.

4. **Sleep timer sheet never shows a selection, may overflow**
   Active-row check is `sleepTimerProvider.remaining == entry.value`, which becomes false one second after the timer starts (remaining ticks down every second). The sheet is also a non-scrolling `Column` of 8 `ListTile`s — can overflow on small screens. Remaining time uses `.inMinutes`, so 59s displays as "0 min".
   → Fix: store the *selected* duration separately for the active-check; wrap in `ListView`; format remaining as mm:ss.

5. **Search race condition (stale results can overwrite fresh ones)**
   The debouncer only delays when a new request *starts* — it doesn't cancel an in-flight request. Fast typing can let an older, slower response land after a newer one and overwrite the UI.
   → Fix: add a request-generation token (same pattern already used in `FavoritesProvider`/`SongsProvider`) — only apply the result if it matches the latest request ID.

6. **`TrendingScreen` missing `mounted` checks**
   Async `setState()` calls (first page, load-more, error paths) have no `if (!mounted) return;` guard, unlike `SingerProfileScreen`. Navigating away mid-request risks a crash.
   → Fix: add `mounted` guards before every `setState()` after an `await`.

7. **Favorites/Downloads show wrong subtitle (category instead of artist)**
   `FavoritesService.fetchFavoriteSongs()` selects from `songs` without the `singers(name)` join, so `singerName` is always null there. `SongRow` then falls back to `song.category ?? 'Unknown'`.
   → Fix: join `singers(name)` in the favorites query, same as `songs_service.dart` does.

8. **Theme tokens defined but mostly ignored**
   `MiniPlayerBar`, `SeekBar`, `SleepTimerSheet`, `SearchScreen`, `SplashScreen`, and `AppDrawer` use hardcoded colors (`#212121`, `Colors.white`, `#0xFF121212`, `#1E1E1E`, `#151515`) instead of `ThemeProvider`'s `t.*` tokens. Switching themes only affects part of the app.
   → Fix: route every color through `context.watch<ThemeProvider>().theme`.

9. **Downloads may write to the wrong path**
   `DownloadsService` passes an absolute path as `DownloadTask.directory`, but `background_downloader` treats `directory` as relative to a `BaseDirectory`. The download can complete on-disk in a different location than `isSongDownloaded()` checks — user downloads a song but the app never marks it as downloaded.
   → Fix: use a `BaseDirectory` + relative subpath instead of an absolute path; verify against the actual save location.

---

## 🟠 P1 — Performance & consistency

10. **Duplicate initialization on Home load** — `HomeScreen`, `SongsScreen`, `FavoritesScreen`, and `DownloadsScreen` all independently call `loadSongs()`/`loadFavorites()` because `IndexedStack` mounts all 5 tabs immediately.
11. **Likes reload repeatedly** — Home, Singer Profile, Search, and each Trending page reload like-status/count per song (2 calls/song, no batching); Trending "load more" re-fetches likes for the *entire* accumulated list each time.
12. **Like-count fallback is wrong when count is legitimately 0** — `count > 0 ? count : song.likeCount` shows stale cached data instead of a genuine zero.
13. **Mini player over-rebuilds** — `context.watch<PlayerProvider>()` rebuilds on every position tick (10–60×/sec) since position/duration/playing-state all live on one provider.
14. **Download-progress updates rebuild entire lists** — `notifyListeners()` in `DownloadsProvider` re-renders all of Songs/Trending/Favorites instead of just the affected row.
15. **No `memCacheWidth`/`memCacheHeight`** on `CachedNetworkImage` — fast scrolling through cover art can spike memory.
16. **Shuffle doesn't use `just_audio`'s built-in shuffle mode** — custom `Random().nextInt()` + manual seek can desync with `LoopMode.all`.
17. **EQ preset selection is a no-op before the first song plays** — `EqualizerService._isInitialized` only becomes true inside `setPlaylist()`.
18. **Mini player gesture conflict** — the whole bar (including the `Slider`) is wrapped in a tap-to-navigate `GestureDetector`, competing with the slider's own drag/tap gestures.
19. **`SongRow` is overloaded** — 7–8 callbacks + flags passed from every parent; adding future actions (share/queue/lyrics) will make this worse. Consider a single actions object instead of individual callbacks.

---

## 🟡 P2 — Cleanup, accessibility, security

20. **Routing inconsistent** — mix of `pushNamed()` and direct `MaterialPageRoute` (Search bypasses the router entirely to open Singer Profile).
21. **Search's singer results only filter from `allSingers`** (whatever's loaded locally) instead of a remote search — results can be incomplete if singers haven't finished loading.
22. **`SingerProfileScreen` uses a non-lazy list** (`_songs.map().toList()`) instead of `ListView.builder`.
23. **Inconsistent state architecture** — Trending and Singer Profile manage state locally with `setState`, while Songs/Singers/Favorites/Downloads are Provider-driven.
24. **Dead connectivity listener** in `main.dart` — `Connectivity().onConnectivityChanged.listen((_) {})` does nothing; `ConnectivityBanner` has its own separate listener.
25. **Splash navigates without awaiting auth** — in the cached-data path, `authProvider.loadCurrentUser()` is fired without `await` before navigating to Home.
26. **Splash dead-ends when offline with no cache** — shows "Could not connect" with no retry-fetch attempt, even though Downloads is meant to work offline.
27. **No pull-to-refresh** anywhere (Songs, Singers, Trending, Favorites).
28. **No buffering indicator** — `PlayerProvider.isLoading` is set but nothing in the UI (mini player, `SongRow`, Now Playing) listens to it; taps feel unresponsive until audio starts.
29. **Touch targets & accessibility gaps** — like button is 32dp (below Material's 48dp minimum); no `Semantics` labels on play/shuffle/like controls; default Walkman Orange theme has low text contrast (~3:1, below WCAG AA).
30. **Premium badge never shows** — `song.isPremium` is never rendered anywhere; `PremiumGate` just passes its child through unconditionally.
31. **Duration formatting breaks on long tracks** — mini player and seek bar both format with `mm:ss` only (no hours), and the unused `padLeft(1, '0')` call is a no-op; `DurationExtensions.asCompact` already exists but isn't used.
32. **Security/config gaps** — Supabase URL/anon key hardcoded in source (`flutter_dotenv` is a dependency but unused for this); `.gitignore` only excludes `.env` (build artifacts, `local.properties`, keystores are not ignored); release build uses debug signing.
33. **Backend/SQL gaps** — repo only ships `sql/setup_likes.sql`; `increment_play_count`, the `singers_with_song_count` view, and `favorites`/`profiles` table + RLS definitions are referenced in code but missing from the repo. Like increment/decrement RPCs aren't `SECURITY DEFINER`, so counts could be manipulated directly via RPC calls.
34. **Downloads always save as `.m4a`** regardless of the actual source audio format.
35. **`PlayerService.dispose()` is never called** (low impact since it's a singleton, but worth noting).
36. **Near-zero test coverage** — only `widget_test.dart` covers a placeholder widget, `Debouncer`, and `Song.fromJson`; nothing for `SongRow`, playlist queueing, splash routing, or likes rollback.

---

## Suggested execution order

1. Fix items **1–9** (P0) — these are the bugs users will notice immediately.
2. Fix items **10–19** (P1) — performance and consistency, no new features blocked by these.
3. Address **32–33** (security/backend) before any production release, regardless of P2 ranking.
4. Everything else in P2 can be tackled incrementally.
