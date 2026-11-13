// Comparing dealers' offers (D27) and the guide to reading one (D31):
// transport a dealer takes off comes off before the verdict; any price is
// turned into the OER it pays for, which doesn't depend on the OER a dealer
// names; and four checks open from the calculator in every language.
//
// Author: SS (Claude Code), Nov 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/calculator_screen.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/offer_guide_sheet.dart';

/// Shaped like backend/data/latest.json, with MPOB's prices for 22 Oct 2026.
final _snapshot = PriceSnapshot.fromJson({
  'success': true,
  'is_indicative': false,
  'formula_status': 'OFFICIAL',
  'scraped_at': '2026-10-23T13:05:00+08:00',
  'ffb': {
    'date': '2026-10-22',
    'source': 'MPOB Daily FFB Reference Price (mill gate)',
    'source_url': 'https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23',
    'is_indicative': false,
    'regions': [
      {
        'region': 'North',
        'date': '2026-10-22',
        'price_1pct_oer': 47.82,
        'avg_oer_pct': 19.89,
      },
      {
        'region': 'Sabah',
        'date': '2026-10-22',
        'price_1pct_oer': 43.06,
        'avg_oer_pct': 21.25,
      },
    ],
  },
  'oer': {'year': 2026, 'month': 9, 'source': 'MPOB Prestasi Sawit (api/oer)'},
});

class _FakePriceService extends PriceService {
  @override
  Future<PriceSnapshot?> fetchLatest() async => _snapshot;
}

Future<void> _pump(WidgetTester tester,
    {AppLocale locale = AppLocale.en}) async {
  // A new key each time, so a second pump in one test starts from nothing.
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      priceServiceProvider.overrideWithValue(_FakePriceService()),
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ],
    child: const MaterialApp(home: CalculatorScreen()),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Fills the form: price per 1% OER, OER, price quoted, transport taken off.
/// A null leaves the field as it is.
Future<void> _enter(WidgetTester tester,
    {String? price, String? oer, String? paid, String? transport}) async {
  final fields = find.byType(TextFormField);
  final values = [price, oer, paid, transport];
  for (var i = 0; i < values.length; i++) {
    if (values[i] != null) await tester.enterText(fields.at(i), values[i]!);
  }
}

void main() {
  group('The sum', () {
    test('transport comes off the quoted price before the verdict', () {
      // RM 790 quoted, RM 25 a tonne taken off: RM 765 is what is kept.
      final r = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18, paidPrice: 790, transport: 25);
      expect(r.quotedPrice, 790);
      expect(r.transport, 25);
      expect(r.paidPrice, 765);
      expect(r.fairPrice, 860.76);
      expect(r.gapRm, -95.76);
      expect(r.verdict, 'AMBER');
    });

    test('a quoted price that looked GREEN can be AMBER once transport is off',
        () {
      final quoted = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18, paidPrice: 820);
      final kept = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18, paidPrice: 820, transport: 25);
      expect(quoted.verdict, 'GREEN');
      expect(kept.verdict, 'AMBER');
    });

    test('with no transport, the price kept is the price quoted', () {
      final r = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 17.25, paidPrice: 750);
      expect(r.paidPrice, 750);
      expect(r.quotedPrice, 750);
      expect(r.transport, 0);
      expect(r.gapRm, -74.9);
    });

    test('transport with no price to take it off is ignored', () {
      final r = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18, transport: 25);
      expect(r.paidPrice, isNull);
      expect(r.transport, 0);
      expect(r.verdict, isNull);
      expect(r.paysForOer, isNull);
    });

    test('the OER a price pays for is the price over the price per 1% OER',
        () {
      final r = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18, paidPrice: 770);
      expect(r.paysForOer, closeTo(16.10, 0.005));
      // It doesn't change with the OER the dealer names.
      final other = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 17.25, paidPrice: 770);
      expect(other.paysForOer, r.paysForOer);
    });

    test('a lower OER figure looks closer to the mill gate but pays for less',
        () {
      // Two offers on the same day: RM 780 "at 18.25%" and RM 770 "at 17.25%".
      final higher = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 18.25, paidPrice: 780);
      final lower = FairPriceResult.calculate(
          price1PctOer: 47.82, gradedOer: 17.25, paidPrice: 770);
      // By the gap, the lower OER figure looks the better offer...
      expect(lower.gapPct!, greaterThan(higher.gapPct!));
      // ...but it pays less per tonne, and the OER it pays for says so.
      expect(lower.paysForOer!, lessThan(higher.paysForOer!));
    });

    test('there is nothing to work out from a price per 1% OER of zero', () {
      final r = FairPriceResult.calculate(
          price1PctOer: 0, gradedOer: 18, paidPrice: 770);
      expect(r.paysForOer, isNull);
    });
  });

  group('In the calculator', () {
    testWidgets('a price quoted before transport, for a chosen region',
        (tester) async {
      await _pump(tester);
      // Choosing the region fills in MPOB's price for it.
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('North').last);
      await _enter(tester, oer: '18.25', paid: '790', transport: '25');
      await _tap(tester, find.text('Calculate'));

      expect(find.text('RM 872.72'), findsOneWidget);
      expect(find.text('RM 790 less RM 25 transport = RM 765 a tonne'),
          findsOneWidget);
      expect(find.text('Gap: RM -107.72 (-12.3%)'), findsOneWidget);
      expect(find.text('AMBER'), findsOneWidget);
      expect(find.text('This price pays for 16.0% OER'), findsOneWidget);
      expect(find.text('RM 765 ÷ 47.82'), findsOneWidget);
      expect(find.text('North mills averaged 19.89% OER (MPOB, Sep 2026)'),
          findsOneWidget);
      expect(find.textContaining('higher is better'), findsOneWidget);
    });

    testWidgets('a price with transport inside it, and no region chosen',
        (tester) async {
      await _pump(tester);
      await _enter(tester, price: '47.82', paid: '770');
      await _tap(tester, find.text('Calculate'));

      expect(find.text('This price pays for 16.1% OER'), findsOneWidget);
      expect(find.text('RM 770 ÷ 47.82'), findsOneWidget);
      // Nothing came off, and no region's average is known.
      expect(find.textContaining('less RM'), findsNothing);
      expect(find.textContaining('mills averaged'), findsNothing);
    });

    testWidgets('with no price entered there is no offer to measure',
        (tester) async {
      await _pump(tester);
      await _enter(tester, price: '47.82', transport: '25');
      await _tap(tester, find.text('Calculate'));

      expect(find.text('RM 860.76'), findsOneWidget);
      expect(find.textContaining('pays for'), findsNothing);
      expect(find.textContaining('less RM'), findsNothing);
    });

    testWidgets('transport that takes the whole price is refused',
        (tester) async {
      await _pump(tester);
      await _enter(tester, price: '47.82', paid: '100', transport: '100');
      await _tap(tester, find.text('Calculate'));

      expect(find.text('Invalid number'), findsOneWidget);
      expect(find.textContaining('pays for'), findsNothing);
    });

    testWidgets('in BM', (tester) async {
      await _pump(tester, locale: AppLocale.ms);
      await _enter(tester, price: '47.82', paid: '790', transport: '25');
      await _tap(tester, find.text('Kira'));

      expect(find.text('RM 790 tolak RM 25 pengangkutan = RM 765 setan'),
          findsOneWidget);
      expect(find.text('Harga ini bersamaan 16.0% OER'), findsOneWidget);
    });

    testWidgets('in 中文, with the region\'s average', (tester) async {
      await _pump(tester, locale: AppLocale.zh);
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('北马').last);
      await _enter(tester, paid: '790', transport: '25');
      await _tap(tester, find.text('计算'));

      expect(find.text('RM 790 扣 RM 25 运输费 = RM 765/公吨'), findsOneWidget);
      expect(find.text('这个价格相当于 16.0% 出油率'), findsOneWidget);
      expect(find.text('北马油厂平均出油率 19.89%（MPOB，2026年9月）'), findsOneWidget);
    });
  });

  group('Before you accept a price', () {
    testWidgets('four checks open from the calculator', (tester) async {
      await _pump(tester);
      await _tap(tester, find.text('Before you accept a price: 4 checks'));

      expect(find.byType(OfferGuideSheet), findsOneWidget);
      expect(find.text('Before you accept a price'), findsOneWidget);
      expect(find.text('1. Is transport inside the price?'), findsOneWidget);
      expect(find.text('2. The OER a dealer names is an offer'), findsOneWidget);
      expect(find.text('3. Ask a second dealer the same day'), findsOneWidget);
      expect(find.text("4. Watch whether MPOB's price has moved"),
          findsOneWidget);
      // It says what it is: one grower's month, not a rule.
      expect(find.textContaining("one grower's month"), findsOneWidget);
    });

    testWidgets('every part of it is shown in each language', (tester) async {
      for (final locale in AppLocale.values) {
        await _pump(tester, locale: locale);
        final strings = stringsFor(locale);
        await _tap(tester, find.text(strings['guide_link']!));

        expect(find.text(strings['guide_title']!), findsOneWidget,
            reason: locale.name);
        expect(find.text(strings['guide_intro']!), findsOneWidget,
            reason: locale.name);
        for (var i = 1; i <= offerGuideChecks; i++) {
          expect(find.text('$i. ${strings['guide_${i}_title']}'), findsOneWidget,
              reason: '${locale.name}: check $i');
          expect(find.text(strings['guide_${i}_body']!), findsOneWidget,
              reason: '${locale.name}: check $i');
        }
        expect(find.text(strings['guide_limits']!), findsOneWidget,
            reason: locale.name);
      }
    });

    test('it names no figure for what a dealer should pay (D23)', () {
      // The guide passes on checks, not a margin: a percentage below MPOB's
      // price would be quoted back at readers as the going rate.
      final gap = RegExp(r'\d+(\.\d+)?\s*%\s*(below|di bawah|以下)|低于.{0,12}\d+\s*%');
      for (final locale in AppLocale.values) {
        final strings = stringsFor(locale);
        for (final key in strings.keys.where((k) => k.startsWith('guide_'))) {
          expect(gap.hasMatch(strings[key]!), isFalse,
              reason: '${locale.name}: $key');
        }
      }
    });
  });
}
