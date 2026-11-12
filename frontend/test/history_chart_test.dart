// History chart layout: round gridlines, spaced date labels, localized dates,
// and the rendered screen showing no colliding labels.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/history_screen.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/widgets/chart_axis.dart';

// The live 30-day window on 30 Sep 2026 (21 trading days).
const _prices = [
  4973.0, 4958.0, 4904.0, 4930.0, 4978.0, 4975.0, 4966.0, 4882.0, 4814.0,
  4850.0, 4880.0, 4936.0, 4898.0, 4810.0, 4768.0, 4772.0, 4672.0, 4664.0,
  4700.0, 4690.0, 4664.0,
];

List<HistoricalPrice> _history() => [
      for (var i = 0; i < _prices.length; i++)
        HistoricalPrice(
          date: '2026-09-${(i + 1).toString().padLeft(2, '0')}',
          cpoPrice: _prices[i],
        ),
    ];

// MPOB's prices for 5-11 Nov 2026. Sabah has a holiday on the 10th here,
// to show a region with no price on a day.
const _ffbDays = [
  FfbHistoryDay(date: '2026-11-05', prices: {'North': 44.96, 'Sabah': 40.30}),
  FfbHistoryDay(date: '2026-11-06', prices: {'North': 44.38, 'Sabah': 39.80}),
  FfbHistoryDay(date: '2026-11-10', prices: {'North': 43.35}),
  FfbHistoryDay(date: '2026-11-11', prices: {'North': 43.54, 'Sabah': 39.03}),
];

/// The History tab with both histories, on a 412 px phone. Taps on links
/// are recorded in [opened].
Future<void> _pumpHistory(WidgetTester tester, {List<Uri>? opened}) async {
  tester.view.physicalSize = const Size(412 * 3, 915 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      historyProvider.overrideWith((ref) async => _history()),
      ffbHistoryProvider.overrideWith((ref) async => _ffbDays),
      linkOpenerProvider.overrideWithValue((uri) async {
        opened?.add(uri);
        return true;
      }),
    ],
    child: const MaterialApp(home: HistoryScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('PriceAxis', () {
    test('uses round gridlines around the live range', () {
      final axis = PriceAxis.fromValues(_prices);
      expect([axis.min, axis.max, axis.interval], [4600.0, 5000.0, 100.0]);
    });

    test('every gridline is a whole step from the minimum', () {
      final axis = PriceAxis.fromValues([4321.0, 4389.0]);
      expect(axis.min % axis.interval, 0);
      expect(axis.max % axis.interval, 0);
      expect(axis.max - axis.min, greaterThan(68));
    });

    test('a flat price still gets a visible range', () {
      final axis = PriceAxis.fromValues([4664.0, 4664.0]);
      expect(axis.max, greaterThan(axis.min));
    });

    test("MPOB's price per 1% OER gets gridlines a ringgit apart", () {
      // The North's range over 14 Oct - 11 Nov 2026.
      final axis = PriceAxis.fromValues([43.35, 47.92], minStep: 0.5);
      expect([axis.min, axis.max, axis.interval], [43.0, 49.0, 1.0]);
    });

    test('a quiet week gets gridlines 50 sen apart', () {
      final axis = PriceAxis.fromValues([43.35, 44.96], minStep: 0.5);
      expect([axis.min, axis.max, axis.interval], [43.0, 45.5, 0.5]);
    });

    test('CPO gridlines are never closer than RM 10', () {
      final axis = PriceAxis.fromValues([4664.0, 4666.0]);
      expect(axis.interval, 10.0);
    });
  });

  group('dateLabelIndices', () {
    test('21 days: first, latest, and evenly spaced between', () {
      expect(dateLabelIndices(21).toList()..sort(), [0, 7, 14, 20]);
    });

    test('never places two labels too close together', () {
      for (var n = 5; n <= 60; n++) {
        final labels = dateLabelIndices(n).toList()..sort();
        expect(labels.first, 0);
        expect(labels.last, n - 1, reason: 'latest date is always labelled');
        for (var i = 1; i < labels.length; i++) {
          expect(labels[i] - labels[i - 1], greaterThanOrEqualTo(2),
              reason: 'n=$n labels=$labels');
        }
      }
    });

    test('short histories label every day', () {
      expect(dateLabelIndices(3), {0, 1, 2});
      expect(dateLabelIndices(0), isEmpty);
    });
  });

  test('localizedDayMonth', () {
    expect(localizedDayMonth('2026-09-28', AppLocale.en), '28 Sep');
    expect(localizedDayMonth('2026-08-03', AppLocale.ms), '3 Ogo');
    expect(localizedDayMonth('not-a-date', AppLocale.en), 'not-a-date');
  });

  testWidgets('History shows round axis labels, short dates, and every day',
      (tester) async {
    tester.view.physicalSize = const Size(412 * 3, 915 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        historyProvider.overrideWith((ref) async => _history()),
        // A data file from before D26: no MPOB history, so only CPO shows.
        ffbHistoryProvider.overrideWith((ref) async => <FfbHistoryDay>[]),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pumpAndSettle();

    // With one history there is nothing to choose between.
    expect(find.byType(SegmentedButton<HistorySeries>), findsNothing);
    // Round gridline labels only: no padded min/max like 4633 or 5009.
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('4600'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^(4633|5009)$')), findsNothing);
    // Dates as "1 Sep"; the latest day is labelled.
    expect(find.text('21 Sep'), findsOneWidget);
    // The table lists every day (newest first), not just the latest ten.
    expect(find.text('2026-09-01'), findsOneWidget);
    expect(find.text('2026-09-21'), findsOneWidget);
  });

  group("MPOB's price history (D26)", () {
    test('a change reads +0.19, −1.03 or 0.00, and a dash for the first day',
        () {
      expect(priceChangeLabel(43.35, 43.54), '+0.19');
      expect(priceChangeLabel(44.38, 43.35), '−1.03');
      expect(priceChangeLabel(47.82, 47.82), '0.00');
      expect(priceChangeLabel(null, 44.96), '–');
    });

    testWidgets("History opens on MPOB's price for the first region",
        (tester) async {
      await _pumpHistory(tester);

      expect(find.text('Price History'), findsOneWidget);
      expect(find.text('MPOB price'), findsOneWidget);
      expect(find.text('CPO price'), findsOneWidget);
      // A chip for each region MPOB has prices for.
      expect(find.widgetWithText(ChoiceChip, 'North'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Sabah'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Sarawak'), findsNothing);
      // The North's days, newest first, each with its change.
      expect(find.text('RM per 1% OER'), findsOneWidget);
      expect(find.text('RM 43.54'), findsOneWidget);
      expect(find.text('+0.19'), findsOneWidget);
      expect(find.text('−1.03'), findsOneWidget);
      expect(find.text('2026-11-05'), findsOneWidget);
      // Gridlines 50 sen apart for a range this small.
      expect(find.text('44.0'), findsOneWidget);
      // The CPO history isn't on screen until asked for.
      expect(find.text('CPO (RM/tonne)'), findsNothing);
    });

    testWidgets('a chip shows another region, without its holiday',
        (tester) async {
      await _pumpHistory(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sabah'));
      await tester.pumpAndSettle();

      expect(find.text('RM 39.03'), findsOneWidget);
      expect(find.text('RM 43.54'), findsNothing);
      // Sabah had no price on the 10th, so the day isn't listed, and the
      // 11th is compared with the 6th.
      expect(find.text('2026-11-10'), findsNothing);
      expect(find.text('−0.77'), findsOneWidget);
    });

    testWidgets('the CPO history is one tap away', (tester) async {
      await _pumpHistory(tester);

      await tester.tap(find.text('CPO price'));
      await tester.pumpAndSettle();

      expect(find.text('CPO (RM/tonne)'), findsOneWidget);
      expect(find.text('2026-09-21'), findsOneWidget);
      expect(find.text('RM per 1% OER'), findsNothing);
    });

    testWidgets("the link under the table opens MPOB's PDF for the latest day",
        (tester) async {
      final opened = <Uri>[];
      await _pumpHistory(tester, opened: opened);

      final link = find.text('MPOB daily reference price, 11 Nov 2026');
      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);

      expect(opened.single.toString(),
          'https://price.mpob.gov.my/pdf/daily/ffb/2026-11-11');
    });

    testWidgets('in Chinese the tab shows no English but MPOB and RM',
        (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          historyProvider.overrideWith((ref) async => _history()),
          ffbHistoryProvider.overrideWith((ref) async => _ffbDays),
          localeProvider
              .overrideWith((ref) => LocaleNotifier(initial: AppLocale.zh)),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('历史价格'), findsOneWidget);
      expect(find.text('MPOB 价格'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, '北马'), findsOneWidget);
      expect(find.text('涨跌'), findsOneWidget);
      expect(find.text('11月11日'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
