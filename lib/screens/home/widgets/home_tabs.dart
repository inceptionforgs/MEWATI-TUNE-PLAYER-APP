import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_themes.dart';
import '../../../providers/theme_provider.dart';

class HomeTabs extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeTabs({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final labels = const [
      AppStrings.navSongs,
      AppStrings.navSingers,
      AppStrings.navTrending,
      AppStrings.navFavorites,
      AppStrings.navDownloads,
    ];

    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: t.textPrimary.withOpacity(0.18), width: 2),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isActive = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Center(
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: isActive
                            ? t.textPrimary
                            : t.textPrimary.withOpacity(0.63),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.only(bottom: -2),
                      decoration: BoxDecoration(
                        color: t.textPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}