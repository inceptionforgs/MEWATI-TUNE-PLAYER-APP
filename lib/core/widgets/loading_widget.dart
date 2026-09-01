import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_strings.dart';
import '../../providers/theme_provider.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: t.accent),
          const SizedBox(height: 16),
          Text(
            message ?? AppStrings.loading,
            style: TextStyle(color: t.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}