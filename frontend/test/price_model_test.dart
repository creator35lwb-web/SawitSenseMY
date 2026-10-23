// Unit tests for SawitSense price models and calculations.
//
// Mirrors backend/tests/test_mpob_scraper.py verification logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/models/price_data.dart';

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

  group('Negotiation target (D23)', () {
    // A reader's receipt: 17.25% OER, RM 750, against MPOB North on 22 Oct.
    final receipt = FairPriceResult.calculate(
      price1PctOer: 47.82,
      gradedOer: 17.25,
      paidPrice: 750.0,
    );

    test('a half cent rounds up, as by hand: 47.82 x 17.25 = 824.90', () {
      expect(receipt.fairPrice, 824.90);
    });

    test('the target is the green edge, in whole ringgit, rounded up', () {
      // 95% of 824.90 is 783.66.
      expect(receipt.targetPrice, 784.0);
    });

    test('an offer at the target is GREEN', () {
      final atTarget = FairPriceResult.calculate(
        price1PctOer: 47.82,
        gradedOer: 17.25,
        paidPrice: receipt.targetPrice,
      );
      expect(atTarget.verdict, 'GREEN');
    });

    test('each 0.25% of OER is worth a quarter of the price per 1%', () {
      expect(receipt.valuePerQuarterOer, 11.96);
    });

    test('the receipt falls RM 34 short of the target', () {
      expect(receipt.verdict, 'AMBER');
      expect(receipt.shortOfTarget, 34.0);
    });

    test('nothing is short without a paid price', () {
      final noPaid =
          FairPriceResult.calculate(price1PctOer: 47.82, gradedOer: 17.25);
      expect(noPaid.shortOfTarget, isNull);
    });

    test('nothing is short when GREEN only because of rounding up', () {
      // 783.70 is within 5% of 824.90, though below the RM 784 target.
      final green = FairPriceResult.calculate(
        price1PctOer: 47.82,
        gradedOer: 17.25,
        paidPrice: 783.70,
      );
      expect(green.verdict, 'GREEN');
      expect(green.shortOfTarget, isNull);
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
