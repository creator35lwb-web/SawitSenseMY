/// Unit tests for SawitSense price models and calculations.
///
/// Mirrors backend/tests/test_mpob_scraper.py verification logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/services/price_service.dart';

void main() {
  group('FairPriceResult.calculate', () {
    test('matches PV-85935 receipt: 42.77 x 18 = 769.86', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
      );
      expect(result.fairPrice, 769.86);
    });

    test('zero OER returns 0', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 0.0,
      );
      expect(result.fairPrice, 0.0);
    });

    test('high OER = 22%', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 22.0,
      );
      expect(result.fairPrice, 940.94);
    });

    test('OER sensitivity: 1% diff at 42.77 = ~42.77', () {
      final r17 = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 17.0,
      );
      final r18 = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
      );
      final diff = r18.fairPrice - r17.fairPrice;
      expect(diff, closeTo(42.77, 0.01));
    });
  });

  group('Verdict logic', () {
    test('GREEN: paid within 5% of fair', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
        paidPrice: 740.0,
      );
      expect(result.verdict, 'GREEN');
    });

    test('AMBER: paid 5-15% below fair', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
        paidPrice: 680.0,
      );
      expect(result.verdict, 'AMBER');
    });

    test('RED: paid >15% below fair', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
        paidPrice: 600.0,
      );
      expect(result.verdict, 'RED');
    });

    test('no verdict when no paid price', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
      );
      expect(result.verdict, isNull);
      expect(result.gapRm, isNull);
    });

    test('exact fair price is GREEN', () {
      final result = FairPriceResult.calculate(
        price1PctOer: 42.77,
        gradedOer: 18.0,
        paidPrice: 769.86,
      );
      expect(result.verdict, 'GREEN');
      expect(result.gapRm, 0.0);
    });
  });

  group('PriceSnapshot.fromJson', () {
    test('parses full JSON structure', () {
      final json = {
        'cpo': {
          'date': '2025-01-10',
          'price_myr_per_tonne': 4650.00,
          'source': 'MPOB BEPI',
        },
        'ffb': {
          'date': '2025-01-10',
          'regions': [
            {
              'region': 'North',
              'date': '2025-01-10',
              'price_1pct_oer': 42.77,
            },
            {
              'region': 'South',
              'date': '2025-01-10',
              'price_1pct_oer': 43.12,
            },
          ],
          'cpo_price': 4650.00,
        },
        'scraped_at': '2025-01-10T08:30:00+08:00',
        'updated_at': '2025-01-10T08:31:00+08:00',
        'success': true,
      };

      final snapshot = PriceSnapshot.fromJson(json);
      expect(snapshot.success, true);
      expect(snapshot.cpo?.priceMyrPerTonne, 4650.00);
      expect(snapshot.ffb?.regions.length, 2);
      expect(snapshot.ffb?.regions[0].region, 'North');
      expect(snapshot.ffb?.regions[0].price1PctOer, 42.77);
    });

    test('handles null cpo gracefully', () {
      final json = {
        'cpo': null,
        'ffb': null,
        'scraped_at': '',
        'updated_at': '',
        'success': false,
      };

      final snapshot = PriceSnapshot.fromJson(json);
      expect(snapshot.success, false);
      expect(snapshot.cpo, isNull);
      expect(snapshot.ffb, isNull);
    });
  });

  group('Demo data', () {
    test('demoSnapshot has all 6 regions', () {
      final demo = PriceService.demoSnapshot();
      expect(demo.success, true);
      expect(demo.ffb?.regions.length, 6);
      expect(demo.cpo?.priceMyrPerTonne, greaterThan(0));
    });

    test('demoHistory returns trading days only', () {
      final history = PriceService.demoHistory();
      expect(history.length, greaterThan(15)); // ~22 trading days in 30 days
      expect(history.length, lessThanOrEqualTo(23));
      for (final entry in history) {
        expect(entry.cpoPrice, greaterThan(0));
      }
    });
  });

  group('RegionalPrice.fromJson', () {
    test('parses valid regional price', () {
      final json = {
        'region': 'Sabah',
        'date': '2025-01-10',
        'price_1pct_oer': 40.65,
        'source': 'MPOB BEPI',
      };
      final rp = RegionalPrice.fromJson(json);
      expect(rp.region, 'Sabah');
      expect(rp.price1PctOer, 40.65);
    });

    test('handles missing fields with defaults', () {
      final rp = RegionalPrice.fromJson({});
      expect(rp.region, '');
      expect(rp.price1PctOer, 0.0);
    });
  });
}
