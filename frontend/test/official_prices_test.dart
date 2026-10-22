// MPOB's official daily FFB reference price in the app (D22): six regional
// prices that differ as MPOB's do, each labelled MPOB's mill-gate price,
// dated, and linked to MPOB's own PDF, with no trace of the retired estimate.
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/config/links.dart';
import 'package:sawitsense_my/l10n/app_en.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/calculator_screen.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/indicative_banner.dart';

const _pdfUrl = 'https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23';

Map<String, dynamic> _region(String name, double price, double oer,
        {String date = '2026-10-22', String? note}) =>
    {
      'region': name,
      'date': date,
      'price_1pct_oer': price,
      'avg_oer_pct': oer,
      'source': 'MPOB Daily FFB Reference Price (mill gate)',
      'is_indicative': false,
      if (note != null) 'note': note,
    };

/// Shaped like backend/data/latest.json since D22, with MPOB's prices for
/// 22 Oct 2026.
Map<String, dynamic> _payload({String sabahDate = '2026-10-22'}) => {
      'success': true,
      'is_indicative': false,
      'formula_status': 'OFFICIAL',
      'scraped_at': '2026-10-23T13:05:00+08:00',
      'cpo': {
        'date': '2026-10-22',
        'price_myr_per_tonne': 4790.0,
        'source': 'MPOC Daily Palm Oil Prices',
        'source_url': 'https://mpoc.org.my/daily-palm-oil-prices/',
      },
      'ffb': {
        'date': '2026-10-22',
        'source': 'MPOB Daily FFB Reference Price (mill gate)',
        'source_url': _pdfUrl,
        'mpob_last_update': '2026-10-22T12:00:00+08:00',
        'is_indicative': false,
        'regions': [
          _region('North', 47.82, 19.89),
          _region('South', 48.20, 20.28),
          _region('Central', 48.12, 19.66),
          _region('East Coast', 48.08, 19.87),
          _region('Sabah', 43.06, 21.25, date: sabahDate),
          _region('Sarawak', 43.49, 19.96, note: 'Miri & Bintulu'),
        ],
      },
      'oer': {
        'year': 2026,
        'month': 9,
        'source': 'MPOB Prestasi Sawit (api/oer)',
        'source_page_url': 'https://prestasisawit.mpob.gov.my/en/oer',
      },
    };

class _FakePriceService extends PriceService {
  _FakePriceService(this.snapshot);
  final PriceSnapshot snapshot;

  @override
  Future<PriceSnapshot?> fetchLatest() async => snapshot;
}

Future<List<Uri>> _pump(WidgetTester tester, Widget screen,
    {AppLocale locale = AppLocale.en, Map<String, dynamic>? payload}) async {
  final opened = <Uri>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      priceServiceProvider.overrideWithValue(
          _FakePriceService(PriceSnapshot.fromJson(payload ?? _payload()))),
      linkOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ],
    child: MaterialApp(home: screen),
  ));
  await tester.pumpAndSettle();
  return opened;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Reading the data', () {
    test("MPOB's link, update time and Sarawak note are read", () {
      final s = PriceSnapshot.fromJson(_payload());
      expect(s.isIndicative, isFalse);
      expect(s.ffb!.sourceUrl, _pdfUrl);
      expect(s.ffb!.mpobLastUpdate, '2026-10-22T12:00:00+08:00');
      expect(s.ffb!.carriedForward, isFalse);
      final sarawak = s.ffb!.regions.last;
      expect(sarawak.note, 'Miri & Bintulu');
      expect(sarawak.avgOerPct, 19.96);
    });

    test("an older snapshot's regional OER still reads as MPOB's average", () {
      final r = RegionalPrice.fromJson(
          {'region': 'South', 'price_1pct_oer': 44.33, 'indicative_oer_pct': 20.28});
      expect(r.avgOerPct, 20.28);
    });

    test("this month's PDF is dated in Malaysian time", () {
      // 17:00 UTC on 22 Oct is already 23 Oct in Malaysia.
      expect(mpobFfbPdfUrl(DateTime.utc(2026, 10, 22, 17)),
          'https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23');
    });

    test('full dates in each language', () {
      expect(localizedDate('2026-10-22', AppLocale.en), '22 Oct 2026');
      expect(localizedDate('2026-10-22', AppLocale.ms), '22 Okt 2026');
      expect(localizedDate('2026-10-22', AppLocale.zh), '2026年10月22日');
      expect(localizedDate('soon', AppLocale.en), 'soon');
    });
  });

  group('Dashboard', () {
    testWidgets("shows MPOB's six regional prices, not an estimate",
        (tester) async {
      await _pump(tester, const DashboardScreen());
      expect(find.byType(IndicativeBanner), findsNothing);
      expect(find.text('Indicative'), findsNothing);
      for (final price in ['47.82', '48.20', '48.12', '48.08', '43.06', '43.49']) {
        expect(find.text('RM $price'), findsOneWidget);
      }
    });

    testWidgets("each card says it is MPOB's mill-gate price", (tester) async {
      await _pump(tester, const DashboardScreen());
      expect(find.text('Source: MPOB, at the mill gate'), findsNWidgets(5));
      expect(find.text('Source: MPOB, at the mill gate · Miri and Bintulu'),
          findsOneWidget);
    });

    testWidgets("the date links to MPOB's PDF, with the dealer note",
        (tester) async {
      final opened = await _pump(tester, const DashboardScreen());
      await _tap(tester, find.text('MPOB daily reference price, 22 Oct 2026'));
      expect(opened, [Uri.parse(_pdfUrl)]);
      expect(find.text(enStrings['dealer_note']!), findsOneWidget);
    });

    testWidgets('a region priced on another day shows its own date',
        (tester) async {
      // A holiday in Sabah only on the 22nd.
      await _pump(tester, const DashboardScreen(),
          payload: _payload(sabahDate: '2026-10-21'));
      expect(find.text('Source: MPOB, at the mill gate · 21 Oct 2026'),
          findsOneWidget);
    });

    testWidgets('in BM', (tester) async {
      await _pump(tester, const DashboardScreen(), locale: AppLocale.ms);
      expect(find.text('Sumber: MPOB, di pintu kilang'), findsNWidgets(5));
      expect(find.text('Sumber: MPOB, di pintu kilang · Miri dan Bintulu'),
          findsOneWidget);
      expect(find.text('Harga panduan harian MPOB, 22 Okt 2026'), findsOneWidget);
    });

    testWidgets('in Chinese', (tester) async {
      await _pump(tester, const DashboardScreen(), locale: AppLocale.zh);
      expect(find.text('来源: MPOB 厂门价'), findsNWidgets(5));
      expect(find.text('来源: MPOB 厂门价 · 美里和民都鲁'), findsOneWidget);
      expect(find.text('MPOB 每日参考价，2026年10月22日'), findsOneWidget);
    });

    testWidgets('"Latest from MPOB" links to the PDF the prices came from',
        (tester) async {
      final opened = await _pump(tester, const DashboardScreen());
      await _tap(tester, find.text('Daily FFB reference prices (PDF)'));
      expect(opened, [Uri.parse(_pdfUrl)]);
    });
  });

  group('Where these prices come from', () {
    testWidgets("names MPOB's price and links to it, without the estimate",
        (tester) async {
      final opened = await _pump(tester, const DashboardScreen());
      await _tap(tester, find.text('Where do these prices come from?'));

      expect(find.text('Where these prices come from'), findsOneWidget);
      expect(find.text("1. MPOB's daily reference price, 22 Oct 2026"),
          findsOneWidget);
      expect(find.text("MPOB's Sarawak price is for Miri and Bintulu."),
          findsOneWidget);
      expect(find.text('2. Average OER by region (MPOB), Sep 2026'),
          findsOneWidget);
      expect(find.textContaining('0.93'), findsNothing);
      expect(find.textContaining('licensee login'), findsNothing);

      // The sheet is drawn over the dashboard, so its own link is the last.
      await _tap(tester, find.text('Daily FFB reference prices (PDF)').last);
      expect(opened, [Uri.parse(_pdfUrl)]);
    });
  });

  group('Fair Price', () {
    testWidgets("the verdict says dealers pay below MPOB's mill-gate price",
        (tester) async {
      await _pump(tester, const CalculatorScreen());
      expect(find.text('Where do these prices come from?'), findsOneWidget);

      // RM 48.20 × 18% = RM 867.60, and RM 900 was paid.
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '48.20');
      await tester.enterText(fields.at(2), '900');
      await _tap(tester, find.text('Calculate'));

      expect(find.text('GREEN'), findsOneWidget);
      expect(find.text(enStrings['dealer_note']!), findsOneWidget);
    });
  });
}
