// The region cards on a small phone (360 px): each region's name shows in
// full in every language, never cut short with "…".
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/widgets/region_price_card.dart';

const _regions = ['North', 'South', 'Central', 'East Coast', 'Sabah', 'Sarawak'];

Widget _cards(AppLocale locale) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final region in _regions)
              RegionPriceCard(
                regionalPrice: RegionalPrice(
                  region: region,
                  date: '2026-10-09',
                  price1PctOer: 41.23,
                  source: 'MPOC CPO x MPOB OER (indicative)',
                  isIndicative: true,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  for (final locale in AppLocale.values) {
    testWidgets('region names show in full at 360 px (${locale.name})',
        (tester) async {
      tester.view.physicalSize = const Size(360, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_cards(locale));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final region in _regions) {
        final name = localizedRegion(region, locale);
        final text = tester.widget<Text>(find.text(name));
        expect(text.overflow, isNot(TextOverflow.ellipsis), reason: name);
        expect(text.maxLines, isNull, reason: name);
      }
      // The indicative chip is still on every card.
      expect(find.text(stringsFor(locale)['indicative_chip']!),
          findsNWidgets(_regions.length));
    });
  }
}
