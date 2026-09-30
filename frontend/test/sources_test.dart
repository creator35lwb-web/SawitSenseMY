// Verifiable sources: every figure links to a public page where it can be
// checked, and the indicative price is shown as a sum anyone can redo.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/config/links.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/app_footer.dart';
import 'package:sawitsense_my/widgets/price_method_sheet.dart';

const _mpocUrl = 'https://mpoc.org.my/daily-palm-oil-prices/';
const _mpobOerUrl = 'https://prestasisawit.mpob.gov.my/en/oer';

/// Shaped like backend/data/latest.json. [withNewFields] = false mimics a
/// payload written before v0.3.2 (no share factor, no MPOB page link).
Map<String, dynamic> _payload({bool withNewFields = true}) => {
      'success': true,
      'is_indicative': true,
      'scraped_at': '2026-09-30T15:09:20.926076+08:00',
      'updated_at': '2026-09-30T15:09:21+08:00',
      'cpo': {
        'date': '2026-09-28',
        'price_myr_per_tonne': 4664.0,
        'source': 'MPOC Daily Palm Oil Prices',
        'source_url': _mpocUrl,
      },
      'ffb': {
        'date': '2026-09-28',
        'is_indicative': true,
        if (withNewFields) 'indicative_share_factor': 0.93,
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
      'oer': {
        'year': 2026,
        'month': 8,
        'source': 'MPOB Prestasi Sawit (api/oer)',
        if (withNewFields) 'source_page_url': _mpobOerUrl,
      },
    };

class _FakePriceService extends PriceService {
  final PriceSnapshot snapshot;

  _FakePriceService(this.snapshot);

  @override
  Future<PriceSnapshot?> fetchLatest() async => snapshot;
}

/// Wraps [child] with a link opener that records what was opened.
Widget _app(Widget child, List<Uri> opened) => ProviderScope(
      overrides: [
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('Parsing the source fields', () {
    test('reads the CPO source, the share factor and the MPOB OER page', () {
      final s = PriceSnapshot.fromJson(_payload());
      expect(s.cpo?.sourceUrl, _mpocUrl);
      expect(s.ffb?.indicativeShareFactor, closeTo(0.93, 1e-9));
      expect(s.oer?.year, 2026);
      expect(s.oer?.month, 8);
      expect(s.oer?.sourcePageUrl, _mpobOerUrl);
    });

    test('payloads from before v0.3.2 still parse', () {
      final s = PriceSnapshot.fromJson(_payload(withNewFields: false));
      expect(s.ffb?.indicativeShareFactor, isNull);
      expect(s.oer?.sourcePageUrl, isNull);
      expect(PriceSnapshot.fromJson({}).oer, isNull);
    });
  });

  group('PriceMethodSheet', () {
    testWidgets('shows the sum anyone can redo and each region\'s OER',
        (tester) async {
      await tester.pumpWidget(
          _app(PriceMethodSheet(snapshot: PriceSnapshot.fromJson(_payload())), []));

      expect(find.text('RM 4664.00 × 0.01 × 0.93 = RM 43.38'), findsOneWidget);
      expect(find.text('Sarawak'), findsOneWidget);
      expect(find.text('19.58%'), findsOneWidget);
      expect(find.textContaining('Aug 2026'), findsWidgets);
      expect(find.textContaining('licensee login'), findsOneWidget);
    });

    testWidgets('source links open the official public pages', (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(_app(
          PriceMethodSheet(snapshot: PriceSnapshot.fromJson(_payload())), opened));

      final mpoc = find.textContaining('MPOC Daily Palm Oil Prices');
      await tester.ensureVisible(mpoc);
      await tester.tap(mpoc);
      final mpob = find.textContaining('choose Aug 2026');
      await tester.ensureVisible(mpob);
      await tester.tap(mpob);

      expect(opened.map((u) => u.toString()), [_mpocUrl, _mpobOerUrl]);
    });

    testWidgets('without the share factor the sum is left out, not guessed',
        (tester) async {
      await tester.pumpWidget(_app(
          PriceMethodSheet(
              snapshot: PriceSnapshot.fromJson(_payload(withNewFields: false))),
          []));

      expect(find.textContaining('× 0.01 ×'), findsNothing);
      expect(find.textContaining('choose'), findsNothing);
    });
  });

  testWidgets('Dashboard: "How is this calculated?" opens the method sheet',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        priceServiceProvider.overrideWithValue(
            _FakePriceService(PriceSnapshot.fromJson(_payload()))),
        linkOpenerProvider.overrideWithValue((uri) async => true),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();

    final link = find.text('How is this calculated?');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('How these prices are calculated'), findsOneWidget);
  });

  testWidgets('Footer "Open data" opens the published dataset', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(_app(const AppFooter(), opened));

    await tester.tap(find.text('Open data'));

    expect(opened.single.toString(), openDataUrl);
  });
}
