import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/sleep_timer_provider.dart';
import '../../../providers/theme_provider.dart';

class SleepTimerSheet extends StatelessWidget {
  const SleepTimerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sleepTimerProvider = context.watch<SleepTimerProvider>();
    final t = context.watch<ThemeProvider>().theme;

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.sleepTimer,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...options.entries.map((entry) {
              final isActive = (entry.value == null && !sleepTimerProvider.isActive) ||
                  (entry.value != null &&
                      sleepTimerProvider.isActive &&
                      sleepTimerProvider.remaining != null &&
                      sleepTimerProvider.remaining == entry.value);
              return ListTile(
                title: Text(
                  entry.key,
                  style: TextStyle(
                    color: isActive ? t.accent : t.textPrimary,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                trailing: isActive
                    ? Icon(Icons.check_circle, color: t.accent)
                    : null,
                onTap: () {
                  if (entry.value == null) {
                    sleepTimerProvider.cancel();
                  } else {
                    sleepTimerProvider.start(entry.value!);
                  }
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
            if (sleepTimerProvider.isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${AppStrings.sleepTimerSet}: ${sleepTimerProvider.remaining?.inMinutes ?? 0} min',
                  style: TextStyle(color: t.accent, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}