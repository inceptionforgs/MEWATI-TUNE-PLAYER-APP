import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/error_handler.dart';
import '../../providers/theme_provider.dart';

class AppErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String errorMessage = ErrorHandler.getMessage(error);
    final t = context.watch<ThemeProvider>().theme;
    final Color onAccent = ThemeData.estimateBrightnessForColor(t.accent) == Brightness.light
        ? Colors.black
        : Colors.white;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE53935),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textPrimary, fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: onAccent,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
