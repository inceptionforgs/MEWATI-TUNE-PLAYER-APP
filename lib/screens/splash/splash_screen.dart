import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_cache_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _startSplashAndNavigate();
  }

  Future<void> _startSplashAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final cachedSongs = await LocalCacheService().getCachedSongs();
    final cachedSingers = await LocalCacheService().getCachedSingers();
    final hasCachedSongs = cachedSongs?.isNotEmpty ?? false;
    final hasCachedSingers = cachedSingers?.isNotEmpty ?? false;

    if (!mounted) return;

    if (hasCachedSongs || hasCachedSingers) {
      // Don't block navigation on auth; start loading user in background.
      authProvider.loadCurrentUser();
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    // No cache and not logged in: likely first launch / offline.
    if (!mounted) return;
    setState(() {
      _showRetry = true;
    });
  }

  Future<void> _retry() async {
    setState(() {
      _showRetry = false;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadCurrentUser();
    if (!mounted) return;
    await _startSplashAndNavigate();
  }

  void _continueOffline() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Scaffold(
      backgroundColor: t.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 64,
                  color: t.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 16,
                  color: t.textSecondary,
                ),
              ),
              if (_showRetry) ...[
                const SizedBox(height: 32),
                Text(
                  'Could not connect. Please check your internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.textPrimary,
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _continueOffline,
                  child: Text(
                    'Continue Offline',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}