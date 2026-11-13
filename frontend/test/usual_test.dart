// An offer measured against the reader's own usual (D30): the calculator
// reads the sales in the journal on the phone, says what OER their prices
// paid for on average, and how far the offer sits above or below that. With
// too few sales to call a habit, it says nothing.
//
// Author: SS (Claude Code), Nov 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/models/sale.dart';
import 'package:sawitsense_my/providers/journal_provider.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/calculator_screen.dart';
import 'package:sawitsense_my/services/journal_codec.dart';
import 'package:sawitsense_my/services/price_service.dart';

/// Three sales in the North, each already set against MPOB's price for its
/// day. They paid for 16.10%, 16.00% and 16.25% OER: 16.12% on average.
const _northSales = [
  Sale(
      date: '2026-10-20',
      region: 'North',
      tonnes: 5,
      price: 770,
      mpobPrice: 47.82,
      mpobDate: '2026-10-20'),
  Sale(
      date: '2026-10-21',
      region: 'North',
      tonnes: 5,
      price: 760,
      mpobPrice: 47.5,
      mpobDate: '2026-10-21'),
  Sale(
      date: '2026-10-22',
      region: 'North',
      tonnes: 5,
      price: 780,
      mpobPrice: 48,
      mpobDate: '2026-10-22'),
];

final _snapshot = PriceSnapshot.fromJson({
  'success': true,
  'is_indicative': false,
  'formula_status': 'OFFICIAL',
  'scraped_at': '2026-10-23T13:05:00+08:00',
  'ffb': {
    'date': '2026-10-22',
    'is_indicative': false,
    'regions': [
      {'region': 'North', 'price_1pct_oer': 47.82, 'avg_oer_pct': 19.89},
      {'region': 'Sabah', 'price_1pct_oer': 43.06, 'avg_oer_pct': 21.25},
    ],
  },
  'oer': {'year': 2026, 'month': 9, 'source': 'MPOB Prestasi Sawit (api/oer)'},
});

class _FakePriceService extends PriceService {
  @override
  Future<PriceSnapshot?> fetchLatest() async => _snapshot;

  @override
  Future<List<HistoricalPrice>> fetchHistory({int days = 30}) async => const [];

  @override
  Future<List<FfbHistoryDay>> fetchFfbHistory({int days = 30}) async =>
      const [];
}

/// A phone that already holds a journal.
class _Phone extends JournalDevice {
  _Phone(this.text);
  String? text;

  @override
  String? read() => text;

  @override
  bool write(String text) {
    this.text = text;
    return true;
  }
}

Future<void> _pump(WidgetTester tester,
    {List<Sale> journal = _northSales,
    AppLocale locale = AppLocale.en}) async {
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      priceServiceProvider.overrideWithValue(_FakePriceService()),
      journalDeviceProvider.overrideWithValue(
          _Phone(journal.isEmpty ? null : encodeJournal(journal))),
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ],
    child: const MaterialApp(home: CalculatorScreen()),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Chooses [region] and enters the price offered, then calculates.
Future<void> _offer(WidgetTester tester, String paid,
    {String region = 'North', String calculate = 'Calculate'}) async {
  await _tap(tester, find.byType(DropdownButtonFormField<String>));
  await _tap(tester, find.text(region).last);
  await tester.enterText(find.byType(TextFormField).at(2), paid);
  await _tap(tester, find.text(calculate));
}

void main() {
  group("The reader's usual", () {
    test('is the OER their latest sales paid for, averaged by weight', () {
      final usual = UsualPrice.of(_northSales)!;
      expect(usual.count, 3);
      expect(usual.paysForOer, closeTo(16.117, 0.001));
    });

    test('weighs a large load more than a small one', () {
      final usual = UsualPrice.of(const [
        Sale(
            date: '2026-10-20',
            region: 'North',
            tonnes: 9,
            price: 800,
            mpobPrice: 50,
            mpobDate: '2026-10-20'), // 16%
        Sale(
            date: '2026-10-21',
            region: 'North',
            tonnes: 0.5,
            price: 900,
            mpobPrice: 50,
            mpobDate: '2026-10-21'), // 18%
        Sale(
            date: '2026-10-22',
            region: 'North',
            tonnes: 0.5,
            price: 900,
            mpobPrice: 50,
            mpobDate: '2026-10-22'), // 18%
      ])!;
      expect(usual.paysForOer, closeTo(16.2, 0.001));
    });

    test('needs three sales that can be compared', () {
      expect(UsualPrice.of(_northSales.take(2)), isNull);
      // A sale without MPOB's price can't be compared, so it doesn't count.
      expect(
          UsualPrice.of([
            ..._northSales.take(2),
            const Sale(
                date: '2026-08-03', region: 'North', tonnes: 4, price: 800),
          ]),
          isNull);
      expect(UsualPrice.of(const []), isNull);
    });

    test('is drawn from the region asked for', () {
      expect(UsualPrice.of(_northSales, region: 'North')!.count, 3);
      expect(UsualPrice.of(_northSales, region: 'Sabah'), isNull);
    });

    test('looks at the ten newest sales only', () {
      final many = [
        // Twelve older sales that paid for 15%...
        for (var day = 1; day <= 12; day++)
          Sale(
              date: '2026-09-${day.toString().padLeft(2, '0')}',
              region: 'North',
              tonnes: 1,
              price: 750,
              mpobPrice: 50,
              mpobDate: '2026-09-${day.toString().padLeft(2, '0')}'),
        // ...and ten newer ones that paid for 16%.
        for (var day = 1; day <= 10; day++)
          Sale(
              date: '2026-10-${day.toString().padLeft(2, '0')}',
              region: 'North',
              tonnes: 1,
              price: 800,
              mpobPrice: 50,
              mpobDate: '2026-10-${day.toString().padLeft(2, '0')}'),
      ];
      final usual = UsualPrice.of(many)!;
      expect(usual.count, 10);
      expect(usual.paysForOer, closeTo(16, 0.001));
    });

    test('puts the difference in ringgit a tonne', () {
      final usual = UsualPrice.of(_northSales)!;
      // RM 800 at 47.82 pays for 16.73%: 0.61 above 16.12, about RM 29.
      expect(usual.differenceRm(800 / 47.82, 47.82), 29);
      // RM 765 pays for 16.00%: about RM 6 below.
      expect(usual.differenceRm(765 / 47.82, 47.82), -6);
    });
  });

  group('In the calculator', () {
    testWidgets('an offer above the usual', (tester) async {
      await _pump(tester);
      await _offer(tester, '800');

      expect(
          find.text(
              'From My Sales: your last 3 sales paid for 16.1% OER on average.'),
          findsOneWidget);
      expect(
          find.text('This offer is RM 29 a tonne above your usual, at this '
              'price per 1% OER.'),
          findsOneWidget);
    });

    testWidgets('an offer below the usual, once transport is off',
        (tester) async {
      await _pump(tester);
      await tester.enterText(find.byType(TextFormField).at(3), '25');
      await _offer(tester, '790');

      expect(
          find.text('This offer is RM 6 a tonne below your usual, at this '
              'price per 1% OER.'),
          findsOneWidget);
    });

    testWidgets('an offer in line with the usual', (tester) async {
      await _pump(tester);
      await _offer(tester, '770.7');

      expect(find.text('This offer is in line with your usual.'),
          findsOneWidget);
    });

    testWidgets('nothing is said with fewer than three sales', (tester) async {
      await _pump(tester, journal: _northSales.sublist(0, 2));
      await _offer(tester, '800');

      expect(find.text('This price pays for 16.7% OER'), findsOneWidget);
      expect(find.textContaining('From My Sales'), findsNothing);
      expect(find.textContaining('your usual'), findsNothing);
    });

    testWidgets('nothing is said with an empty journal', (tester) async {
      await _pump(tester, journal: const []);
      await _offer(tester, '800');

      expect(find.textContaining('From My Sales'), findsNothing);
    });

    testWidgets('sales in another region are not the yardstick',
        (tester) async {
      await _pump(tester);
      await _offer(tester, '700', region: 'Sabah');

      expect(find.text('This price pays for 16.3% OER'), findsOneWidget);
      expect(find.textContaining('From My Sales'), findsNothing);
    });

    testWidgets('with a price typed in, every sale counts', (tester) async {
      await _pump(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '47.82');
      await tester.enterText(fields.at(2), '800');
      await _tap(tester, find.text('Calculate'));

      expect(find.textContaining('your last 3 sales'), findsOneWidget);
    });

    testWidgets('with no price entered there is no offer to measure',
        (tester) async {
      await _pump(tester);
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('North').last);
      await _tap(tester, find.text('Calculate'));

      expect(find.textContaining('From My Sales'), findsNothing);
    });

    testWidgets('in BM', (tester) async {
      await _pump(tester, locale: AppLocale.ms);
      await _offer(tester, '800', region: 'Utara', calculate: 'Kira');

      expect(
          find.text('Daripada Jualan Saya: 3 jualan terakhir anda secara '
              'purata bersamaan 16.1% OER.'),
          findsOneWidget);
      expect(
          find.text('Tawaran ini RM 29 setan lebih tinggi daripada kebiasaan '
              'anda, pada harga per 1% OER ini.'),
          findsOneWidget);
    });

    testWidgets('in 中文', (tester) async {
      await _pump(tester, locale: AppLocale.zh);
      await _offer(tester, '800', region: '北马', calculate: '计算');

      expect(find.text('来自“我的销售”：您最近 3 笔销售平均相当于 16.1% 出油率。'), findsOneWidget);
      expect(find.text('按此每 1% 出油率价格，这个报价比您平时每公吨高 RM 29。'), findsOneWidget);
    });
  });
}
