// The app must never show made-up prices: when real data can't be loaded the
// providers return null / an empty list, and the Dashboard says so.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/price_service.dart';

class _FakePriceService extends PriceService {
  final PriceSnapshot? latest;
  final List<HistoricalPrice> history;

  _FakePriceService({this.latest, this.history = const []});

  @override
  Future<PriceSnapshot?> fetchLatest() async => latest;

  @override
  Future<List<HistoricalPrice>> fetchHistory({int days = 30}) async => history;
}

ProviderContainer _containerWith(PriceService service) {
  final container = ProviderContainer(
    overrides: [priceServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('latestPriceProvider', () {
    test('is null when loading fails, never demo data', () async {
      final container = _containerWith(_FakePriceService());
      expect(await container.read(latestPriceProvider.future), isNull);
    });

    test('treats a snapshot marked unsuccessful as unavailable', () async {
      final container = _containerWith(_FakePriceService(
        latest: PriceSnapshot.fromJson({
          'success': false,
          'scraped_at': '2026-09-30T08:00:00+08:00',
        }),
      ));
      expect(await container.read(latestPriceProvider.future), isNull);
    });

    test('passes a successful snapshot through unchanged', () async {
      final snap = PriceSnapshot.fromJson({
        'success': true,
        'scraped_at': '2026-09-30T08:00:00+08:00',
        'cpo': {'date': '2026-09-29', 'price_myr_per_tonne': 4664.0},
      });
      final container = _containerWith(_FakePriceService(latest: snap));
      expect(await container.read(latestPriceProvider.future), same(snap));
    });
  });

  group('historyProvider', () {
    test('is empty when no history loads, never synthetic prices', () async {
      final container = _containerWith(_FakePriceService());
      expect(await container.read(historyProvider.future), isEmpty);
    });
  });

  testWidgets('Dashboard shows an honest unavailable state, not demo prices',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [priceServiceProvider.overrideWithValue(_FakePriceService())],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining("Prices can't be loaded"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('RM '), findsNothing);
  });
}
