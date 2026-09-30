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
      overrides: [historyProvider.overrideWith((ref) async => _history())],
      child: const MaterialApp(home: HistoryScreen()),
    ));
    await tester.pumpAndSettle();

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
}
