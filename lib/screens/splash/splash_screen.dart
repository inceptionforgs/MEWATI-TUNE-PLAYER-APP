import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
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
      authProvider.loadCurrentUser();
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.music_note,
                size: 64,
                color: Color(0xFFE67E22),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFB3B3B3),
              ),
            ),
            if (_showRetry) ...[
              const SizedBox(height: 32),
              const Text(
                'Could not connect. Please check your internet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFE53935), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}