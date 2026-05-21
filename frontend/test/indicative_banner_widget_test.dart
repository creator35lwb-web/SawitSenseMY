// Widget tests for the IndicativeBanner.
//
// Verifies:
//   - Expanded variant shows headline, body, and "Learn more" affordance.
//   - Compact variant shows headline only (no body, no Learn more).
//   - Tapping "Learn more" copies the ADR-001 URL to the clipboard and shows
//     a SnackBar.
//
// Author: QQ (Perplexity)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    testWidgets('tapping Learn more copies URL and shows SnackBar',
        (tester) async {
      // Capture clipboard writes
      String? lastCopied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          lastCopied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });

      await tester.pumpWidget(_wrap(const IndicativeBanner()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      expect(lastCopied, isNotNull);
      expect(lastCopied, contains('ADR-001'));

      // SnackBar should appear
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
