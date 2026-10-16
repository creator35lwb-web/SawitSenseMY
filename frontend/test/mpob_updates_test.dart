// "Latest from MPOB" (D18): which MPOB OER month is in the prices and when
// it arrived, in EN, BM and 中文, with links to MPOB's own news pages.
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/config/links.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/mpob_updates_card.dart';

/// Shaped like backend/data/latest.json.
Map<String, dynamic> _payload({String? inAppSince}) => {
      'success': true,
      'is_indicative': true,
      'scraped_at': '2026-10-17T05:01:37+08:00',
      'cpo': {
        'date': '2026-10-15',
        'price_myr_per_tonne': 4619.0,
        'source': 'MPOC Daily Palm Oil Prices',
        'source_url': 'https://mpoc.org.my/daily-palm-oil-prices/',
      },
      'ffb': {
        'date': '2026-10-15',
        'is_indicative': true,
        'regions': [
          {
            'region': 'Sabah',
            'price_1pct_oer': 42.96,
            'indicative_oer_pct': 21.25,
            'is_indicative': true,
          },
        ],
      },
      'oer': {
        'year': 2026,
        'month': 9,
        'source': 'MPOB Prestasi Sawit (api/oer)',
        if (inAppSince != null) 'in_app_since': inAppSince,
      },
    };

class _FakePriceService extends PriceService {
  _FakePriceService(this.snapshot);
  final PriceSnapshot snapshot;

  @override
  Future<PriceSnapshot?> fetchLatest() async => snapshot;
}

String Function(String) _trFor(AppLocale locale) =>
    (key) => stringsFor(locale)[key] ?? key;

OerInfo _oer({String? inAppSince}) =>
    PriceSnapshot.fromJson(_payload(inAppSince: inAppSince)).oer!;

void main() {
  group('Reading the data', () {
    test('in_app_since is read when present', () {
      expect(_oer(inAppSince: '2026-10-12').inAppSince, '2026-10-12');
    });

    test('a snapshot written before D18 has no date', () {
      expect(_oer().inAppSince, isNull);
    });
  });

  group('The OER line', () {
    test('English, with the date it arrived', () {
      expect(
        MpobUpdatesCard.oerLine(_oer(inAppSince: '2026-10-12'), AppLocale.en,
            _trFor(AppLocale.en)),
        "These prices use MPOB's OER for Sep 2026, added on 12 Oct.",
      );
    });

    test('BM, with the date it arrived', () {
      expect(
        MpobUpdatesCard.oerLine(_oer(inAppSince: '2026-10-12'), AppLocale.ms,
            _trFor(AppLocale.ms)),
        'Harga ini menggunakan OER MPOB bagi Sep 2026, ditambah pada 12 Okt.',
      );
    });

    test('Chinese, with the date it arrived', () {
      expect(
        MpobUpdatesCard.oerLine(_oer(inAppSince: '2026-10-12'), AppLocale.zh,
            _trFor(AppLocale.zh)),
        '这些价格采用 MPOB 2026年9月的出油率，于10月12日更新。',
      );
    });

    test('an unknown or unreadable date is left out, not guessed', () {
      for (final since in [null, 'soon']) {
        expect(
          MpobUpdatesCard.oerLine(
              _oer(inAppSince: since), AppLocale.en, _trFor(AppLocale.en)),
          "These prices use MPOB's OER for Sep 2026.",
        );
      }
    });

    test('no OER month, no line', () {
      expect(
          MpobUpdatesCard.oerLine(null, AppLocale.en, _trFor(AppLocale.en)),
          isNull);
      expect(
          MpobUpdatesCard.oerLine(
              const OerInfo(year: 2026), AppLocale.en, _trFor(AppLocale.en)),
          isNull);
    });
  });

  group('On the dashboard', () {
    Future<List<Uri>> pumpDashboard(WidgetTester tester,
        {AppLocale locale = AppLocale.en}) async {
      final opened = <Uri>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          priceServiceProvider.overrideWithValue(_FakePriceService(
              PriceSnapshot.fromJson(_payload(inAppSince: '2026-10-12')))),
          linkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
          localeProvider
              .overrideWith((ref) => LocaleNotifier(initial: locale)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ));
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('says which OER month is in the prices, and since when',
        (tester) async {
      await pumpDashboard(tester);
      expect(find.text('Latest from MPOB'), findsOneWidget);
      expect(
          find.text(
              "These prices use MPOB's OER for Sep 2026, added on 12 Oct."),
          findsOneWidget);
    });

    testWidgets("the links open MPOB's own news pages", (tester) async {
      final opened = await pumpDashboard(tester);

      for (final label in ['Palm oil news', 'MPOB press releases']) {
        final link = find.text(label);
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();
      }

      expect(opened, [Uri.parse(mpobNewsUrl), Uri.parse(mpobPressUrl)]);
      expect(opened.every((u) => u.host == 'mpob.gov.my'), isTrue);
      expect(opened.every((u) => u.scheme == 'https'), isTrue);
    });

    testWidgets('in Chinese', (tester) async {
      await pumpDashboard(tester, locale: AppLocale.zh);
      expect(find.text('MPOB 最新消息'), findsOneWidget);
      expect(find.text('这些价格采用 MPOB 2026年9月的出油率，于10月12日更新。'),
          findsOneWidget);
      expect(find.text('棕油新闻'), findsOneWidget);
      // Chinese has no italics; the note stays upright.
      final note = tester.widget<Text>(find.text('以上链接为 MPOB 网站，内容为英文和马来文。'));
      expect(note.style?.fontStyle, FontStyle.normal);
    });
  });
}
