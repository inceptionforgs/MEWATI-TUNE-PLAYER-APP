# Mewati Tune Player 🎵

**Mewati music ka ghar**

A Flutter-based music streaming app dedicated to Mewati regional folk songs.  
Built with ❤️ for Mewati music lovers, designed to run on free tiers and scale as a future premium service.

## ✨ Features

- Splash screen with logo and tagline
- Anonymous sign-in
- Home screen with 5 tabs: Songs, Singers, Trending, Favorites, Downloads
- Full-screen search overlay
- Songs library with infinite scroll
- Singers library with aggregated song counts
- Trending songs sorted by play count
- Now Playing screen with album art, seek bar, shuffle/repeat
- Mini player bar
- Favorites sync with Supabase
- Downloads offline playback
- Three switchable themes
- Equalizer presets
- Sleep timer with fade-out
- Like feature with count
- Offline metadata cache
- Connectivity banner
- Debug panel (development only)

## 🛠 Tech Stack

- Flutter (Android-first)
- Provider state management
- Supabase (Postgres + Auth)
- Cloudflare R2 for audio
- just_audio for playback
- background_downloader for offline

## 🚀 Setup

1. Create a Supabase project and run the SQL scripts in `sql/` folder.
2. Enable Anonymous Auth in Supabase.
3. Update `lib/config/supabase_config.dart` with your Supabase URL and anon key.
4. Run `flutter pub get` and `flutter run`.

Made with ❤️ for Mewati music lovers.