// Share: the plain site link goes to the phone's share sheet, or to a panel
// with WhatsApp, Facebook, X, LinkedIn, email and copy link. No Telegram, and
// nothing about the reader is added to the link.
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/config/links.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/dashboard_screen.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/services/price_service.dart';
import 'package:sawitsense_my/services/share_links.dart';
import 'package:sawitsense_my/widgets/share_button.dart';

class _FakePriceService extends PriceService {
  @override
  Future<PriceSnapshot?> fetchLatest() async => PriceSnapshot.fromJson({
        'success': true,
        'scraped_at': '2026-10-09T08:18:42+08:00',
        'cpo': {'date': '2026-10-07', 'price_myr_per_tonne': 4524.0},
      });
}

class _FakeNativeShare extends NativeShare {
  _FakeNativeShare({required this.isAvailable});
  final bool isAvailable;
  final shared = <String>[];

  @override
  bool get available => isAvailable;

  @override
  Future<void> share({
    required String title,
    required String text,
    required String url,
  }) async =>
      shared.add('$title|$text|$url');
}

Widget _dashboard(List<Uri> opened, _FakeNativeShare native,
        {AppLocale locale = AppLocale.en}) =>
    ProviderScope(
      overrides: [
        priceServiceProvider.overrideWithValue(_FakePriceService()),
        linkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return true;
        }),
        nativeShareProvider.overrideWithValue(native),
        localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );

Future<void> _tapShare(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final button = find.byType(ShareButton);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  test('share links carry only the pitch and the plain site address', () {
    Uri link(ShareTarget t) =>
        shareLink(t, text: 'Hi there', url: siteUrl, emailSubject: 'Prices');
    final site = Uri.encodeComponent(siteUrl);
    expect(link(ShareTarget.whatsapp).toString(),
        'https://wa.me/?text=Hi%20there%20$site');
    expect(link(ShareTarget.facebook).toString(),
        'https://www.facebook.com/sharer/sharer.php?u=$site');
    expect(link(ShareTarget.x).toString(),
        'https://x.com/intent/tweet?text=Hi%20there&url=$site');
    expect(link(ShareTarget.linkedin).toString(),
        'https://www.linkedin.com/sharing/share-offsite/?url=$site');
    expect(link(ShareTarget.email).toString(),
        'mailto:?subject=Prices&body=Hi%20there%0A%0A$site');
    expect(siteUrl, 'https://creator35lwb-web.github.io/SawitSenseMY/');
    expect(ShareTarget.values.map((t) => t.name), isNot(contains('telegram')));
  });

  testWidgets('on a phone, Share opens the phone\'s own share sheet',
      (tester) async {
    final native = _FakeNativeShare(isAvailable: true);
    await tester.pumpWidget(_dashboard([], native));
    await _tapShare(tester);

    expect(native.shared, hasLength(1));
    expect(native.shared.single, endsWith('|$siteUrl'));
    expect(find.byType(SharePanel), findsNothing);
  });

  testWidgets('elsewhere, the panel shares to WhatsApp and copies the link',
      (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
        _dashboard(opened, _FakeNativeShare(isAvailable: false)));
    await _tapShare(tester);

    expect(find.byType(SharePanel), findsOneWidget);
    expect(find.text('Telegram'), findsNothing);
    for (final name in ['WhatsApp', 'Facebook', 'X', 'LinkedIn', 'Email']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }

    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    await tester.tap(find.text('Copy link'));
    await tester.pumpAndSettle();
    expect(copied, siteUrl);
    expect(find.text('Link copied'), findsOneWidget);

    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(opened.single.host, 'wa.me');
    expect(opened.single.queryParameters['text'], endsWith(siteUrl));
  });

  testWidgets('the panel speaks the reader\'s language', (tester) async {
    await tester.pumpWidget(_dashboard(
        [], _FakeNativeShare(isAvailable: false),
        locale: AppLocale.zh));
    await _tapShare(tester);

    expect(find.text('分享 SawitSense MY'), findsOneWidget);
    expect(find.text('复制链接'), findsOneWidget);
    expect(find.text('电子邮件'), findsOneWidget);
  });
}
