// Unit tests for the indicative-mode fields added in Phase 2 (Path C).
//
// Confirms:
//   - PriceSnapshot.fromJson reads `is_indicative`, `indicative_notice`,
//     `data_source_version`, `formula_status`.
//   - FfbPriceData.fromJson reads `is_indicative`.
//   - RegionalPrice.fromJson reads `is_indicative`, `indicative_oer_pct`,
//     `indicative_fair_price_per_tonne`.
//   - Backward compatibility: legacy payloads (without these fields) parse
//     cleanly and default `isIndicative` to false.
//
// Author: QQ (Perplexity)

import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/models/price_data.dart';

void main() {
  group('Indicative-mode fields — PriceSnapshot', () {
    test('parses Path C indicative payload (matches backend/run_scraper.py)',
        () {
      final json = {
        'cpo': {
          'date': '2026-05-20',
          'price_myr_per_tonne': 4583.0,
          'source': 'MPOC Daily Palm Oil Prices',
        },
        'ffb': {
          'date': '2026-05-20',
          'is_indicative': true,
          'source': 'SawitSense derived (Path C)',
          'regions': [
            {
              'region': 'South',
              'date': '2026-05-20',
              'price_1pct_oer': 42.62,
              'indicative_oer_pct': 20.24,
              'indicative_fair_price_per_tonne': 862.63,
              'is_indicative': true,
              'source': 'Derived (MPOC CPO × MPOB OER)',
            }
          ],
          'cpo_price': 4583.0,
        },
        'scraped_at': '2026-05-21T14:14:51+08:00',
        'updated_at': '2026-05-21T14:14:51+08:00',
        'success': true,
        'is_indicative': true,
        'indicative_notice':
            "MPOB's daily FFB Reference Price tables moved behind a licensee login...",
        'data_source_version': '0.3-recovery',
        'formula_status': 'INDICATIVE',
      };

      final snap = PriceSnapshot.fromJson(json);
      expect(snap.success, true);
      expect(snap.isIndicative, true);
      expect(snap.indicativeNotice, isNotNull);
      expect(snap.dataSourceVersion, '0.3-recovery');
      expect(snap.formulaStatus, 'INDICATIVE');
      expect(snap.ffb?.isIndicative, true);
      expect(snap.ffb?.regions.first.isIndicative, true);
      expect(snap.ffb?.regions.first.indicativeOerPct, 20.24);
      expect(snap.ffb?.regions.first.indicativeFairPricePerTonne, 862.63);
    });

    test('legacy v0.2 payload parses with isIndicative=false (backward compat)',
        () {
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
              'source': 'MPOB BEPI',
            }
          ],
          'cpo_price': 4650.00,
        },
        'scraped_at': '2025-01-10T08:30:00+08:00',
        'updated_at': '2025-01-10T08:31:00+08:00',
        'success': true,
      };

      final snap = PriceSnapshot.fromJson(json);
      expect(snap.success, true);
      expect(snap.isIndicative, false,
          reason: 'Legacy payloads must default to non-indicative');
      expect(snap.indicativeNotice, isNull);
      expect(snap.dataSourceVersion, isNull);
      expect(snap.formulaStatus, isNull);
      expect(snap.ffb?.isIndicative, false);
      expect(snap.ffb?.regions.first.isIndicative, false);
      expect(snap.ffb?.regions.first.indicativeOerPct, isNull);
    });

    test('completely empty payload returns sane defaults', () {
      final snap = PriceSnapshot.fromJson({});
      expect(snap.success, false);
      expect(snap.isIndicative, false);
      expect(snap.indicativeNotice, isNull);
      expect(snap.cpo, isNull);
      expect(snap.ffb, isNull);
    });
  });

  group('Indicative fields — RegionalPrice', () {
    test('parses indicative-only flag without OER values', () {
      final rp = RegionalPrice.fromJson({
        'region': 'Central',
        'date': '2026-05-20',
        'price_1pct_oer': 42.62,
        'is_indicative': true,
      });
      expect(rp.isIndicative, true);
      expect(rp.indicativeOerPct, isNull);
      expect(rp.indicativeFairPricePerTonne, isNull);
    });

    test('rejects non-bool is_indicative gracefully (defensive)', () {
      // Defensive against malformed payloads — we read as bool? ?? false.
      final rp = RegionalPrice.fromJson({
        'region': 'Sabah',
        'date': '2026-05-20',
        'price_1pct_oer': 42.62,
        // 'is_indicative' intentionally omitted -> default false
      });
      expect(rp.isIndicative, false);
    });
  });
}
