// Freshness badge: the ethical framework's GREEN / AMBER / RED thresholds,
// the age in words (EN + BM), and the badge widget.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/freshness.dart';
import 'package:sawitsense_my/widgets/freshness_badge.dart';

void main() {
  // 30 Sep 2026, 15:00 MYT.
  final now = DateTime.utc(2026, 9, 30, 7);

  String hoursAgo(num hours) => now
      .subtract(Duration(minutes: (hours * 60).round()))
      .toIso8601String();

  group('Freshness.of (ethical framework thresholds)', () {
    test('under 6 hours is GREEN', () {
      expect(Freshness.of(hoursAgo(5.9), now).level, FreshnessLevel.green);
    });

    test('6 to 12 hours is AMBER', () {
      expect(Freshness.of(hoursAgo(6), now).level, FreshnessLevel.amber);
      expect(Freshness.of(hoursAgo(11.9), now).level, FreshnessLevel.amber);
    });

    test('12 hours or more is RED', () {
      expect(Freshness.of(hoursAgo(12), now).level, FreshnessLevel.red);
      expect(Freshness.of(hoursAgo(72), now).level, FreshnessLevel.red);
    });

    test('a missing or unreadable timestamp is RED with an unknown age', () {
      final missing = Freshness.of('', now);
      expect(missing.level, FreshnessLevel.red);
      expect(missing.age, isNull);
      expect(Freshness.of('not-a-date', now).level, FreshnessLevel.red);
    });

    test('reads the backend format, including the +08:00 offset', () {
      // 13:00 MYT is 05:00 UTC: two hours before `now`.
      expect(Freshness.of('2026-09-30T13:00:00+08:00', now).age,
          const Duration(hours: 2));
      // Microseconds, as run_scraper.py writes them.
      expect(Freshness.of('2026-09-30T14:02:08.778503+08:00', now).age,
          isNotNull);
    });

    test('a timestamp slightly in the future counts as just now', () {
      final f = Freshness.of(hoursAgo(-0.1), now);
      expect(f.level, FreshnessLevel.green);
      expect(f.age, Duration.zero);
    });
  });

  group('localizedAge', () {
    test('English', () {
      expect(localizedAge(Duration.zero, AppLocale.en), 'Updated just now');
      expect(localizedAge(const Duration(minutes: 1), AppLocale.en),
          'Updated 1 minute ago');
      expect(localizedAge(const Duration(minutes: 45), AppLocale.en),
          'Updated 45 minutes ago');
      expect(localizedAge(const Duration(hours: 1), AppLocale.en),
          'Updated 1 hour ago');
      expect(localizedAge(const Duration(hours: 5, minutes: 30), AppLocale.en),
          'Updated 5 hours ago');
      expect(localizedAge(const Duration(days: 2, hours: 3), AppLocale.en),
          'Updated 2 days ago');
      expect(localizedAge(null, AppLocale.en), 'Update time unknown');
    });

    test('Bahasa Malaysia', () {
      expect(localizedAge(const Duration(hours: 5), AppLocale.ms),
          'Dikemas kini 5 jam lalu');
      expect(localizedAge(const Duration(days: 1), AppLocale.ms),
          'Dikemas kini 1 hari lalu');
      expect(localizedAge(null, AppLocale.ms), 'Masa kemas kini tidak diketahui');
    });
  });

  test('localizedDateTime uses Malay month names in BM', () {
    final t = DateTime(2026, 8, 3, 9, 5);
    expect(localizedDateTime(t, AppLocale.en), '3 Aug 2026, 09:05');
    expect(localizedDateTime(t, AppLocale.ms), '3 Ogo 2026, 09:05');
  });

  group('FreshnessBadge', () {
    Widget wrap(Widget child) =>
        ProviderScope(child: MaterialApp(home: Scaffold(body: child)));

    testWidgets('fresh data: status and age in words, no warning',
        (tester) async {
      await tester.pumpWidget(
          wrap(FreshnessBadge(scrapedAt: hoursAgo(2), now: now)));
      expect(find.textContaining('Up to date'), findsOneWidget);
      expect(find.textContaining('Updated 2 hours ago'), findsOneWidget);
      expect(find.textContaining('Check the date'), findsNothing);
    });

    testWidgets('old data: RED with a hint to check the date', (tester) async {
      await tester.pumpWidget(
          wrap(FreshnessBadge(scrapedAt: hoursAgo(50), now: now)));
      expect(find.textContaining('Out of date'), findsOneWidget);
      expect(find.textContaining('Updated 2 days ago'), findsOneWidget);
      expect(find.textContaining('Check the date'), findsOneWidget);
    });
  });
}
