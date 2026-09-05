// File: lib/screens/player/widgets/sleep_timer_sheet.dart
//
// Restyled rows to match the pill-card look used elsewhere (drawer,
// song rows): custom rows instead of default ListTile, per-theme corner
// radius, active row highlighted with an accent border + glow-dot
// (same visual language as the drawer's theme/EQ rows). Keeping the
// real 8-option sheet (Off/5/10/15/20/30/60/120 min) as agreed —
// SleepTimerProvider.start()/cancel() and all option values are
// unchanged.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/themes/app_theme_id.dart';
import '../../../core/extensions/duration_extensions.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../providers/theme_provider.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) => duration.asCompact;

  static double _radius(AppThemeId id) {
    switch (id) {
      case AppThemeId.cyberBlack:
        return 4;
      case AppThemeId.silverChrome:
        return 10;
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepTimerProvider = context.watch<SleepTimerProvider>();
    final t = context.watch<ThemeProvider>().theme;
    final radius = _radius(t.id);

    final options = <String, Duration?>{
      AppStrings.sleepTimerOff: null,
      AppStrings.sleepTimer5: const Duration(minutes: 5),
      AppStrings.sleepTimer10: const Duration(minutes: 10),
      AppStrings.sleepTimer15: const Duration(minutes: 15),
      AppStrings.sleepTimer20: const Duration(minutes: 20),
      AppStrings.sleepTimer30: const Duration(minutes: 30),
      AppStrings.sleepTimer60: const Duration(hours: 1),
      AppStrings.sleepTimer120: const Duration(hours: 2),
    };

    final activeDuration = sleepTimerProvider.totalDuration;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: t.textPrimary.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              AppStrings.sleepTimer,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options.entries.map((entry) {
                  final isActive = (entry.value == null && activeDuration == null) ||
                      (entry.value != null && activeDuration == entry.value);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(radius),
                      onTap: () {
                        if (entry.value == null) {
                          sleepTimerProvider.cancel();
                        } else {
                          sleepTimerProvider.start(entry.value!);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.08) : t.surface,
                          borderRadius: BorderRadius.circular(radius),
                          border: Border.all(
                            color: isActive ? t.accent : t.textPrimary.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: isActive ? t.accent : t.textPrimary.withOpacity(0.85),
                                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? t.accent : Colors.white.withOpacity(0.5),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: t.accent.withOpacity(0.7),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (sleepTimerProvider.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${AppStrings.sleepTimerSet}: ${_formatDuration(sleepTimerProvider.remaining ?? Duration.zero)}',
                  style: TextStyle(color: t.accent, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
