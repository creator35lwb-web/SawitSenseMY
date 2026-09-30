// Language menu: English, Bahasa Malaysia, 简体中文.
//
// The app bar shows the current language's short name. The menu lists each
// language in its own script, so a reader can find theirs whichever language
// is showing.
//
// Patch: SS (Claude Code), Sep 2026 — a menu instead of the EN|BM toggle, now
// that there are three languages (D10).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return PopupMenuButton<AppLocale>(
      // In all three languages, so anyone can tell what the button does.
      tooltip: 'Language · Bahasa · 语言',
      initialValue: locale,
      onSelected: (choice) =>
          ref.read(localeProvider.notifier).setLocale(choice),
      itemBuilder: (context) => [
        for (final option in AppLocale.values)
          CheckedPopupMenuItem<AppLocale>(
            value: option,
            checked: option == locale,
            child: Text(option.nativeName),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.translate, size: 18, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                locale.shortName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
