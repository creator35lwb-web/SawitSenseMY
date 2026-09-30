// Widget tests for the IndicativeBanner.
//
// Verifies:
//   - Expanded variant shows headline, body, and "Learn more" affordance.
//   - Compact variant shows headline only (no body, no Learn more).
//   - Tapping "Learn more" opens ADR-001 (via linkOpenerProvider).
//
// Author: QQ (Perplexity)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sawitsense_my/services/link_opener.dart';
import 'package:sawitsense_my/widgets/indicative_banner.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('IndicativeBanner', () {
    testWidgets('expanded variant shows headline + body + learn more',
        (tester) async {
      await tester.pumpWidget(_wrap(const IndicativeBanner()));
      await tester.pumpAndSettle();

      // Headline is always visible
      expect(
        find.textContaining('Indicative', findRichText: true),
        findsWidgets,
      );
      // Body is visible in expanded variant
      expect(
        find.textContaining('MPOB'),
        findsWidgets,
      );
      // Learn more affordance is visible
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('compact variant hides body and learn more', (tester) async {
      await tester.pumpWidget(_wrap(const IndicativeBanner(compact: true)));
      await tester.pumpAndSettle();

      // Headline still visible
      expect(find.textContaining('Indicative'), findsWidgets);
      // No learn-more icon in compact mode
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('tapping Learn more opens ADR-001', (tester) async {
      // Patch: SS (Claude Code), Sep 2026 — the link now opens instead of
      // being copied to the clipboard.
      final opened = <Uri>[];
      await tester.pumpWidget(ProviderScope(
        overrides: [
          linkOpenerProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return true;
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: IndicativeBanner())),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(opened.single.toString(), contains('ADR-001'));
    });
  });
}
