import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_theme.dart';
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
    final playerProvider = context.watch<PlayerProvider>();
    final t = context.watch<ThemeProvider>().theme;

    if (!playerProvider.hasSong) {
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

    final song = playerProvider.currentSong!;

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