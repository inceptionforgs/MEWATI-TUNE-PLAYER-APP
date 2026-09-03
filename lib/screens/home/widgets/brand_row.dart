// File: lib/screens/home/widgets/brand_row.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class BrandRow extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;

  const BrandRow({
    Key? key,
    required this.onMenuTap,
    required this.onSearchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: t.textPrimary),
            onPressed: onMenuTap,
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.textPrimary, width: 2),
            ),
            child: Icon(Icons.music_note, color: t.textPrimary, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mewati Tune',
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, color: t.textPrimary),
            onPressed: onSearchTap,
          ),
        ],
      ),
    );
  }
}
