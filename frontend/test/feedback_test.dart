// Feedback: each option opens the feedback form (D14) with that choice and
// the app details filled in, and nothing claims feedback was sent (K17).
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
import 'package:sawitsense_my/services/feedback_link.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/widgets/app_footer.dart';
import 'package:sawitsense_my/widgets/feedback_button.dart';

final _snapshot = PriceSnapshot.fromJson({
  'success': true,
  'is_indicative': true,
  'scraped_at': '2026-10-01T13:45:04+08:00',
  'cpo': {
    'date': '2026-09-30',
    'price_myr_per_tonne': 4610.0,
    'source': 'MPOC Daily Palm Oil Prices',
  },
  'ffb': {
    'date': '2026-09-30',
    'is_indicative': true,
    'regions': [
      {
        'region': 'North',
        'price_1pct_oer': 42.87,
        'indicative_oer_pct': 19.57,
        'is_indicative': true,
      },
    ],
  },
});

class _FakePriceService extends PriceService {
  @override
  Future<PriceSnapshot?> fetchLatest() async => _snapshot;
}

void main() {
  test('the options match the form word for word', () {
    // From the form Alton created on 1 Oct 2026 (docs/feedback-form.md). If
    // the form's wording changes, these must change with it, or the form
    // opens with nothing selected.
    expect(FeedbackTopic.helpful.formOption,
        'Ini berguna · This is helpful · 很有帮助');
    expect(FeedbackTopic.confusing.formOption,
        'Sesuatu mengelirukan · Something is confusing · 有些地方看不懂');
    expect(FeedbackTopic.wrongPrice.formOption,
        'Harga nampak salah · A price looks wrong · 价格好像不对');
  });

  test('the link carries only the choice and the app details', () {
    final link = feedbackFormLink(
      FeedbackTopic.wrongPrice,
      appDetails: feedbackAppDetails(
        version: '0.3.12',
        language: 'zh',
        pricesScrapedAt: '2026-10-01T13:45:04+08:00',
      ),
    );
    expect(link.toString(), startsWith(feedbackFormUrl));
    expect(link.queryParameters, {
      'usp': 'pp_url',
      feedbackTopicField: 'Harga nampak salah · A price looks wrong · 价格好像不对',
      feedbackAppDetailsField: 'v0.3.12 · zh · prices 2026-10-01T13:45:04+08:00',
    });
  });

  test('before prices load, the app details say so', () {
    expect(feedbackAppDetails(version: '0.3.12', language: 'ms'),
        'v0.3.12 · ms · prices not loaded');
  });

  testWidgets('choosing "price looks wrong" opens the form, without a fake '
      '"Thank you"', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [
        priceServiceProvider.overrideWithValue(_FakePriceService()),
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
        localeProvider
            .overrideWith((ref) => LocaleNotifier(initial: AppLocale.zh)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ));
    await tester.pumpAndSettle();

    final button = find.byType(FeedbackButton);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    // The dialog says where the reader is going before they tap.
    expect(find.text('将打开一份简短的 Google 表单，无需登录。请勿填写个人资料。'),
        findsOneWidget);

    await tester.tap(find.text('价格好像不对'));
    await tester.pumpAndSettle();

    expect(opened, hasLength(1));
    expect(opened.single.queryParameters[feedbackTopicField],
        FeedbackTopic.wrongPrice.formOption);
    expect(opened.single.queryParameters[feedbackAppDetailsField],
        'v$appVersion · zh · prices 2026-10-01T13:45:04+08:00');
    expect(find.byType(SnackBar), findsNothing);
  });
}
