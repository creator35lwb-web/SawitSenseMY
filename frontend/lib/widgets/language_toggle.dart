// BM/EN language toggle button.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEn = locale == AppLocale.en;

    return Tooltip(
      message: isEn ? 'Tukar ke Bahasa Malaysia' : 'Switch to English',
      child: TextButton(
        onPressed: () => ref.read(localeProvider.notifier).toggle(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 36),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EN',
              style: TextStyle(
                fontWeight: isEn ? FontWeight.bold : FontWeight.normal,
                color: isEn ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('|', style: TextStyle(color: Colors.white38)),
            ),
            Text(
              'BM',
              style: TextStyle(
                fontWeight: !isEn ? FontWeight.bold : FontWeight.normal,
                color: !isEn ? Colors.white : Colors.white60,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
