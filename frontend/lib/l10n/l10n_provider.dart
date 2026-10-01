// Localization provider: English, Bahasa Malaysia and Simplified Chinese.
//
// Patch: SS (Claude Code), Sep 2026 — Simplified Chinese (D10); region names
// come from the string tables; the app opens in the reader's language (D11).
import 'dart:ui' show FontStyle, Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_en.dart';
import 'app_ms.dart';
import 'app_zh.dart';
import 'language_store_stub.dart'
    if (dart.library.js_interop) 'language_store_web.dart';

enum AppLocale {
  en('EN', 'English', Locale('en')),
  ms('BM', 'Bahasa Malaysia', Locale('ms')),
  zh('中文', '简体中文',
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

  const AppLocale(this.shortName, this.nativeName, this.flutterLocale);

  /// Shown in the app bar, e.g. "BM".
  final String shortName;

  /// The language's name in its own script, for the language menu.
  final String nativeName;

  /// The language as Flutter knows it. Flutter sets the page's `lang` from
  /// it (e.g. "zh-Hans"), so screen readers use the right voice.
  final Locale flutterLocale;
}

/// The language to open in: the reader's last choice on this phone if there
/// is one, otherwise the first of the phone's languages that the app speaks,
/// otherwise English. A phone set to any Chinese, Traditional included, opens
/// in Simplified Chinese.
AppLocale initialLocale({
  String? saved,
  List<Locale> deviceLocales = const [],
}) {
  for (final locale in AppLocale.values) {
    if (locale.name == saved) return locale;
  }
  for (final device in deviceLocales) {
    for (final locale in AppLocale.values) {
      if (locale.name == device.languageCode) return locale;
    }
  }
  return AppLocale.en;
}

class LocaleNotifier extends StateNotifier<AppLocale> {
  /// Starts in [initial]; [save] keeps the reader's choices for next time.
  LocaleNotifier({AppLocale initial = AppLocale.en, this.save})
      : super(initial);

  final void Function(String code)? save;

  /// The reader chose [locale]: show it, and remember it on this phone.
  void setLocale(AppLocale locale) {
    state = locale;
    save?.call(locale.name);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>(
  (ref) => LocaleNotifier(
    initial: initialLocale(
      saved: readSavedLanguage(),
      deviceLocales: PlatformDispatcher.instance.locales,
    ),
    save: saveLanguage,
  ),
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

/// Italic for asides in English and BM. Chinese has no italics, and slanted
/// characters look broken, so Chinese stays upright.
FontStyle asideFontStyle(AppLocale locale) =>
    locale == AppLocale.zh ? FontStyle.normal : FontStyle.italic;

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
