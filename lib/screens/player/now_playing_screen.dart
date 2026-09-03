import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_drawer.dart';
import '../../providers/player_provider.dart';
import '../../providers/theme_provider.dart';
import 'widgets/album_art.dart';
import 'widgets/now_playing_actions.dart';
import 'widgets/player_controls.dart';
import 'widgets/seek_bar.dart';
import 'widgets/sleep_timer_sheet.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  void _openEqualizerDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    // Use context.select to avoid rebuilding whole screen on every position tick.
    final hasSong = context.select<PlayerProvider, bool>((p) => p.hasSong);
    final song = context.select<PlayerProvider, dynamic>((p) => p.currentSong);
    // Fixed (Item 7): surface PlayerProvider.errorMessage as a banner with
    // a retry action, since playback/seek/next/previous failures set it
    // but nothing displayed it before.
    final errorMessage =
        context.select<PlayerProvider, String?>((p) => p.errorMessage);

    if (!hasSong || song == null) {
      return Scaffold(
        backgroundColor: t.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left,
                          color: t.textPrimary, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('No song selected',
                      style: TextStyle(color: t.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: t.screenGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left,
                          color: t.textPrimary, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'NOW PLAYING',
                      style: TextStyle(
                        color: t.textPrimary.withOpacity(0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 34),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AlbumArt(song: song, t: t),
                    const SizedBox(height: 22),
                    Text(
                      song.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.singerName ?? 'Unknown Artist',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Fixed (Item 7): error banner + retry, shown when
                    // PlayerProvider.errorMessage is set.
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Unable to play this song',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                errorMessage,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: t.textPrimary.withOpacity(0.75),
                                  fontSize: 12,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    final playerProvider =
                                        context.read<PlayerProvider>();
                                    playerProvider.clearError();
                                    playerProvider.togglePlayPause();
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    NowPlayingActions(
                      song: song,
                      onTimerTap: _openSleepTimerSheet,
                      onEqualizerTap: _openEqualizerDrawer,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: SeekBar(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                child: PlayerControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
