// Languages: every string exists in English, Bahasa Malaysia and Simplified
// Chinese; dates, ages and regions read naturally in each; the language menu
// switches the whole app, and the Chinese screens show no English or raw keys.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/app_en.dart';
import 'package:sawitsense_my/l10n/app_zh.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/calculator_screen.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/language_menu.dart';

/// Shaped like backend/data/latest.json.
final _snapshot = PriceSnapshot.fromJson({
  'success': true,
  'is_indicative': true,
  'scraped_at': '2026-09-30T15:09:20.926076+08:00',
  'cpo': {
    'date': '2026-09-28',
    'price_myr_per_tonne': 4664.0,
    'source': 'MPOC Daily Palm Oil Prices',
    'source_url': 'https://mpoc.org.my/daily-palm-oil-prices/',
  },
  'ffb': {
    'date': '2026-09-28',
    'is_indicative': true,
    'indicative_share_factor': 0.93,
    'regions': [
      {
        'region': 'North',
        'price_1pct_oer': 43.38,
        'indicative_oer_pct': 19.57,
        'is_indicative': true,
      },
      {
        'region': 'Sarawak',
        'price_1pct_oer': 43.38,
        'indicative_oer_pct': 19.58,
        'is_indicative': true,
      },
    ],
  },
  'oer': {'year': 2026, 'month': 8, 'source': 'MPOB Prestasi Sawit (api/oer)'},
});

class _FakePriceService extends PriceService {
  @override
  Future<PriceSnapshot?> fetchLatest() async => _snapshot;
}

/// [screen] in Chinese, with prices loaded.
Widget _inChinese(Widget screen) => ProviderScope(
      overrides: [
        priceServiceProvider.overrideWithValue(_FakePriceService()),
        localeProvider
            .overrideWith((ref) => LocaleNotifier()..setLocale(AppLocale.zh)),
      ],
      child: MaterialApp(home: screen),
    );

/// Every plain Text currently on screen.
Iterable<String> _shownText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>();

void main() {
  group('String tables', () {
    test('every language has every key', () {
      for (final locale in AppLocale.values) {
        expect(stringsFor(locale).keys.toSet(), enStrings.keys.toSet(),
            reason: locale.name);
      }
    });

    test('no string is empty', () {
      for (final locale in AppLocale.values) {
        for (final e in stringsFor(locale).entries) {
          expect(e.value.trim(), isNotEmpty, reason: '${locale.name}: ${e.key}');
        }
      }
    });

    test('placeholders such as {month} survive translation', () {
      final placeholder = RegExp(r'\{\w+\}');
      Set<String> placeholdersIn(String s) =>
          placeholder.allMatches(s).map((m) => m[0]!).toSet();
      for (final e in enStrings.entries) {
        for (final locale in AppLocale.values) {
          expect(placeholdersIn(stringsFor(locale)[e.key]!),
              placeholdersIn(e.value),
              reason: '${locale.name}: ${e.key}');
        }
      }
    });

    test('the Chinese table is in Chinese', () {
      // Catches English pasted in by mistake. The name and tagline stay as
      // they are in every language.
      final han = RegExp(r'[一-鿿]');
      const sharedEverywhere = {'app_title', 'app_tagline'};
      for (final e in zhStrings.entries) {
        if (sharedEverywhere.contains(e.key)) continue;
        expect(han.hasMatch(e.value), isTrue, reason: e.key);
      }
    });
  });

  group('Chinese formats', () {
    test('regions use the names Malaysian Chinese readers use', () {
      expect(localizedRegion('North', AppLocale.zh), '北马');
      expect(localizedRegion('Central', AppLocale.zh), '中马');
      expect(localizedRegion('East Coast', AppLocale.zh), '东海岸');
      expect(localizedRegion('Sarawak', AppLocale.zh), '砂拉越');
      // English and BM are unchanged.
      expect(localizedRegion('East Coast', AppLocale.en), 'East Coast');
      expect(localizedRegion('East Coast', AppLocale.ms), 'Pantai Timur');
      // An unknown region is shown as it is, not as a key.
      expect(localizedRegion('Labuan', AppLocale.zh), 'Labuan');
    });

    test('dates read 2026年8月3日 and chart labels 9月28日', () {
      expect(localizedDateTime(DateTime(2026, 8, 3, 9, 5), AppLocale.zh),
          '2026年8月3日 09:05');
      expect(localizedMonthYear(2026, 8, AppLocale.zh), '2026年8月');
      expect(localizedDayMonth('2026-09-28', AppLocale.zh), '9月28日');
      expect(localizedDayMonth('not-a-date', AppLocale.zh), 'not-a-date');
    });

    test('ages read "5 小时前更新"', () {
      expect(localizedAge(Duration.zero, AppLocale.zh), '刚刚更新');
      expect(localizedAge(const Duration(minutes: 45), AppLocale.zh),
          '45 分钟前更新');
      expect(localizedAge(const Duration(hours: 5, minutes: 30), AppLocale.zh),
          '5 小时前更新');
      expect(localizedAge(const Duration(days: 2), AppLocale.zh), '2 天前更新');
      expect(localizedAge(null, AppLocale.zh), '更新时间未知');
    });
  });

  testWidgets('the language menu lists each language in its own script and '
      'switches the app', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            appBar: AppBar(actions: const [LanguageMenu()]),
            body: Text(ref.watch(trProvider)('nav_history')),
          ),
        ),
      ),
    ));
    expect(find.text('Price History'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);

    await tester.tap(find.byType(LanguageMenu));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Bahasa Malaysia'), findsOneWidget);
    expect(find.text('简体中文'), findsOneWidget);

    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(find.text('历史价格'), findsOneWidget);
    expect(find.text('中文'), findsOneWidget);

    await tester.tap(find.byType(LanguageMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bahasa Malaysia'));
    await tester.pumpAndSettle();
    expect(find.text('Sejarah Harga'), findsOneWidget);
    expect(find.text('BM'), findsOneWidget);
  });

  group('In Chinese', () {
    // English strings that differ in Chinese; none should be left on screen.
    final english = {
      for (final e in enStrings.entries)
        if (zhStrings[e.key] != e.value) e.value,
    };

    testWidgets('the dashboard shows no English and no raw keys',
        (tester) async {
      await tester.pumpWidget(_inChinese(const DashboardScreen()));
      await tester.pumpAndSettle();

      expect(find.text('每日价格总览'), findsOneWidget);
      expect(find.text('原棕油现货价'), findsOneWidget);
      expect(find.text('北马'), findsOneWidget);
      expect(find.text('砂拉越'), findsOneWidget);
      // Chinese has no italics; the disclaimer stays upright.
      final disclaimer =
          tester.widget<Text>(find.text(zhStrings['footer_disclaimer']!));
      expect(disclaimer.style?.fontStyle, FontStyle.normal);

      final shown = _shownText(tester).toList();
      expect(shown.where(enStrings.containsKey), isEmpty);
      expect(shown.where(english.contains), isEmpty);
    });

    testWidgets('the calculator\'s form errors and verdict are in Chinese',
        (tester) async {
      await tester.pumpWidget(_inChinese(const CalculatorScreen()));
      await tester.pumpAndSettle();

      final calculate = find.text('计算');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      expect(find.text('必填'), findsOneWidget);

      // RM 43.38 × 18% = RM 780.84; being paid RM 700 is 10.4% below: amber.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '43.38');
      await tester.enterText(fields.at(2), '700');
      await tester.ensureVisible(calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();

      expect(find.text('黄灯'), findsOneWidget);
      expect(find.text('注意 — 低于基准 5-15%'), findsOneWidget);
      final shown = _shownText(tester).toList();
      expect(shown.where(enStrings.containsKey), isEmpty);
      expect(shown.where(english.contains), isEmpty);
    });
  });
}
