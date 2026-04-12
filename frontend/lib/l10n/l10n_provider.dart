/// Localization provider for BM/EN toggle.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_en.dart';
import 'app_ms.dart';

enum AppLocale { en, ms }

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.en);

  void toggle() {
    state = state == AppLocale.en ? AppLocale.ms : AppLocale.en;
  }

  void setLocale(AppLocale locale) {
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(),
);

/// Get a translated string by key.
final trProvider = Provider.family<String, String>((ref, key) {
  final locale = ref.watch(localeProvider);
  final strings = locale == AppLocale.en ? enStrings : msStrings;
  return strings[key] ?? key;
});

/// Helper to get region name in current locale.
String localizedRegion(String englishRegion, AppLocale locale) {
  if (locale == AppLocale.en) return englishRegion;
  const regionMap = {
    'North': 'Utara',
    'South': 'Selatan',
    'Central': 'Tengah',
    'East Coast': 'Pantai Timur',
    'Sabah': 'Sabah',
    'Sarawak': 'Sarawak',
  };
  return regionMap[englishRegion] ?? englishRegion;
}
