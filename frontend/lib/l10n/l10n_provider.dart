// Localization provider: English, Bahasa Malaysia and Simplified Chinese.
//
// Patch: SS (Claude Code), Sep 2026 — Simplified Chinese (D10); region names
// come from the string tables.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_en.dart';
import 'app_ms.dart';
import 'app_zh.dart';

enum AppLocale {
  en('EN', 'English'),
  ms('BM', 'Bahasa Malaysia'),
  zh('中文', '简体中文');

  const AppLocale(this.shortName, this.nativeName);

  /// Shown in the app bar, e.g. "BM".
  final String shortName;

  /// The language's name in its own script, for the language menu.
  final String nativeName;
}

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.en);

  void setLocale(AppLocale locale) {
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(),
);

/// The string table for [locale].
Map<String, String> stringsFor(AppLocale locale) => switch (locale) {
      AppLocale.en => enStrings,
      AppLocale.ms => msStrings,
      AppLocale.zh => zhStrings,
    };

// Returns a translation function: tr('key') -> localized string.
final trProvider = Provider<String Function(String)>((ref) {
  final strings = stringsFor(ref.watch(localeProvider));
  return (String key) => strings[key] ?? key;
});

const _regionKeys = {
  'North': 'region_north',
  'South': 'region_south',
  'Central': 'region_central',
  'East Coast': 'region_east_coast',
  'Sabah': 'region_sabah',
  'Sarawak': 'region_sarawak',
};

/// A region's name in [locale], from its English name in the data.
/// Unknown regions are shown as they are.
String localizedRegion(String englishRegion, AppLocale locale) =>
    stringsFor(locale)[_regionKeys[englishRegion]] ?? englishRegion;

/// How long ago data was updated, e.g. "Updated 3 hours ago" /
/// "Dikemas kini 3 jam lalu" / "3 小时前更新". A null [age] means the time
/// is unknown.
String localizedAge(Duration? age, AppLocale locale) {
  if (age == null) {
    return switch (locale) {
      AppLocale.en => 'Update time unknown',
      AppLocale.ms => 'Masa kemas kini tidak diketahui',
      AppLocale.zh => '更新时间未知',
    };
  }
  if (age.inMinutes < 1) {
    return switch (locale) {
      AppLocale.en => 'Updated just now',
      AppLocale.ms => 'Dikemas kini sebentar tadi',
      AppLocale.zh => '刚刚更新',
    };
  }
  final (int n, String enUnit, String msUnit, String zhUnit) =
      age.inHours < 1
          ? (age.inMinutes, 'minute', 'minit', '分钟')
          : age.inDays < 1
              ? (age.inHours, 'hour', 'jam', '小时')
              : (age.inDays, 'day', 'hari', '天');
  return switch (locale) {
    AppLocale.en => 'Updated $n $enUnit${n == 1 ? '' : 's'} ago',
    AppLocale.ms => 'Dikemas kini $n $msUnit lalu',
    AppLocale.zh => '$n $zhUnit前更新',
  };
}

const _enMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _msMonths = [
  'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
];

// Chinese dates use numbered months (e.g. 9月), so they are formatted below
// rather than looked up here.
String _monthName(int month, AppLocale locale) =>
    (locale == AppLocale.ms ? _msMonths : _enMonths)[month - 1];

/// A timestamp in the device's time zone, e.g. "30 Sep 2026, 15:09" (Malay
/// month names in BM) or "2026年9月30日 15:09".
String localizedDateTime(DateTime time, AppLocale locale) {
  final t = time.toLocal();
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return locale == AppLocale.zh
      ? '${t.year}年${t.month}月${t.day}日 $hh:$mm'
      : '${t.day} ${_monthName(t.month, locale)} ${t.year}, $hh:$mm';
}

/// A month, e.g. "Aug 2026" / "Ogo 2026" / "2026年8月" (MPOB publishes OER
/// monthly).
String localizedMonthYear(int year, int month, AppLocale locale) =>
    locale == AppLocale.zh
        ? '$year年$month月'
        : '${_monthName(month, locale)} $year';

/// A short date for chart labels, e.g. "28 Sep" / "3 Ogo" / "9月28日", from
/// "2026-09-28". Returns [isoDate] unchanged if it can't be parsed.
String localizedDayMonth(String isoDate, AppLocale locale) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return locale == AppLocale.zh
      ? '${d.month}月${d.day}日'
      : '${d.day} ${_monthName(d.month, locale)}';
}
