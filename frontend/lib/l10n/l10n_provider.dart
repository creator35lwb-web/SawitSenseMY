// Localization provider for BM/EN toggle.
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

// Returns a translation function: tr('key') -> localized string.
final trProvider = Provider<String Function(String)>((ref) {
  final locale = ref.watch(localeProvider);
  final strings = locale == AppLocale.en ? enStrings : msStrings;
  return (String key) => strings[key] ?? key;
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

/// How long ago data was updated, e.g. "Updated 3 hours ago" /
/// "Dikemas kini 3 jam lalu". A null [age] means the time is unknown.
String localizedAge(Duration? age, AppLocale locale) {
  final en = locale == AppLocale.en;
  if (age == null) {
    return en ? 'Update time unknown' : 'Masa kemas kini tidak diketahui';
  }
  if (age.inMinutes < 1) {
    return en ? 'Updated just now' : 'Dikemas kini sebentar tadi';
  }
  final int n;
  final String enUnit;
  final String msUnit;
  if (age.inHours < 1) {
    n = age.inMinutes;
    enUnit = 'minute';
    msUnit = 'minit';
  } else if (age.inDays < 1) {
    n = age.inHours;
    enUnit = 'hour';
    msUnit = 'jam';
  } else {
    n = age.inDays;
    enUnit = 'day';
    msUnit = 'hari';
  }
  return en
      ? 'Updated $n $enUnit${n == 1 ? '' : 's'} ago'
      : 'Dikemas kini $n $msUnit lalu';
}

/// A timestamp in the device's time zone, e.g. "30 Sep 2026, 15:09"
/// (BM month names in Malay).
String localizedDateTime(DateTime time, AppLocale locale) {
  const enMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const msMonths = [
    'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
  ];
  final t = time.toLocal();
  final month = (locale == AppLocale.en ? enMonths : msMonths)[t.month - 1];
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} $month ${t.year}, $hh:$mm';
}
