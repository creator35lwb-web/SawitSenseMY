// "Latest from MPOB" (D18): links to MPOB's own pages (its daily FFB price
// PDF since D22, and its news), in EN, BM and 中文. It names no OER month and
// no date (D20, K24): "Sep 2026, added on
// 12 Oct" read as out of date beside a fresh price, and the price per 1% OER
// doesn't use MPOB's OER.
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

/// Shaped like backend/data/latest.json. The `oer` block carries the month
/// and the date it arrived, which the card must not show.
Map<String, dynamic> _payload() => {
      'success': true,
      'is_indicative': true,
      'scraped_at': '2026-10-23T01:06:04+08:00',
      'cpo': {
        'date': '2026-10-21',
        'price_myr_per_tonne': 4767.0,
        'source': 'MPOC Daily Palm Oil Prices',
        'source_url': 'https://mpoc.org.my/daily-palm-oil-prices/',
      },
      'ffb': {
        'date': '2026-10-21',
        'is_indicative': true,
        'regions': [
          {
            'region': 'Sabah',
            'price_1pct_oer': 44.33,
            'indicative_oer_pct': 21.25,
            'is_indicative': true,
          },
        ],
      },
      'oer': {
        'year': 2026,
        'month': 9,
        'source': 'MPOB Prestasi Sawit (api/oer)',
        'in_app_since': '2026-10-12',
      },
    };

class _FakePriceService extends PriceService {
  _FakePriceService(this.snapshot);
  final PriceSnapshot snapshot;

  @override
  Future<PriceSnapshot?> fetchLatest() async => snapshot;
}

Future<List<Uri>> _pumpDashboard(WidgetTester tester,
    {AppLocale locale = AppLocale.en}) async {
  final opened = <Uri>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [
      priceServiceProvider.overrideWithValue(
          _FakePriceService(PriceSnapshot.fromJson(_payload()))),
      linkOpenerProvider.overrideWithValue((uri) async {
        opened.add(uri);
        return true;
      }),
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  ));
  await tester.pumpAndSettle();
  return opened;
}

/// Every text in the card.
List<String> _cardTexts(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(
        of: find.byType(MpobUpdatesCard), matching: find.byType(Text)))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList();

void main() {
  testWidgets('shows the title, the three links and the note', (tester) async {
    await _pumpDashboard(tester);
    expect(_cardTexts(tester), [
      'Latest from MPOB',
      'Daily FFB reference prices (PDF)',
      'Palm oil news',
      'MPOB press releases',
      "On MPOB's website, in English and BM.",
    ]);
  });

  for (final locale in AppLocale.values) {
    testWidgets('names no OER month and no date (${locale.name})',
        (tester) async {
      await _pumpDashboard(tester, locale: locale);
      final texts = _cardTexts(tester);
      expect(texts, isNotEmpty);
      for (final text in texts) {
        expect(text, isNot(contains('OER')));
        expect(text, isNot(contains('出油率')));
        expect(text, isNot(matches(RegExp('[0-9]'))));
      }
    });
  }

  testWidgets("the links open MPOB's own pages", (tester) async {
    final opened = await _pumpDashboard(tester);

    for (final label in [
      'Daily FFB reference prices (PDF)',
      'Palm oil news',
      'MPOB press releases',
    ]) {
      final link = find.text(label);
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
    }

    // This snapshot gives no PDF link, so the card links to this month's.
    expect(opened.first.toString(),
        startsWith('https://price.mpob.gov.my/pdf/daily/ffb/'));
    expect(opened.skip(1), [Uri.parse(mpobNewsUrl), Uri.parse(mpobPressUrl)]);
    expect(opened.every((u) => u.host.endsWith('mpob.gov.my')), isTrue);
    expect(opened.every((u) => u.scheme == 'https'), isTrue);
  });

  testWidgets('in Chinese', (tester) async {
    await _pumpDashboard(tester, locale: AppLocale.zh);
    expect(_cardTexts(tester), [
      'MPOB 最新消息',
      '每日鲜果串参考价（PDF）',
      '棕油新闻',
      'MPOB 新闻稿',
      '以上链接为 MPOB 网站，内容为英文和马来文。',
    ]);
    // Chinese has no italics; the note stays upright.
    final note = tester.widget<Text>(find.text('以上链接为 MPOB 网站，内容为英文和马来文。'));
    expect(note.style?.fontStyle, FontStyle.normal);
  });
}
