// Data freshness badge: GREEN / AMBER / RED, the age in words, and the exact
// update time.
//
// The ethical framework requires freshness to be visible wherever prices are
// shown. The colour follows the framework's thresholds (models/freshness.dart);
// the words and timestamp let a smallholder see when data is simply from the
// last trading day, e.g. at weekends.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';
import '../models/freshness.dart';

class FreshnessBadge extends ConsumerWidget {
  /// The snapshot's `scraped_at` timestamp (ISO 8601).
  final String scrapedAt;

  /// Clock override for tests; defaults to the current time.
  final DateTime? now;

  const FreshnessBadge({super.key, required this.scrapedAt, this.now});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final freshness = Freshness.of(scrapedAt, now ?? DateTime.now());

    final (MaterialColor color, IconData icon, String label) =
        switch (freshness.level) {
      FreshnessLevel.green =>
        (Colors.green, Icons.check_circle_outline, tr('freshness_green')),
      FreshnessLevel.amber =>
        (Colors.amber, Icons.schedule, tr('freshness_amber')),
      FreshnessLevel.red =>
        (Colors.red, Icons.error_outline, tr('freshness_red')),
    };
    final ageText = localizedAge(freshness.age, locale);
    final scrapedTime = freshness.scrapedAt;
    final textStyle = TextStyle(color: color.shade900, fontSize: 12);

    return Semantics(
      container: true,
      label: '$label. $ageText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.shade400),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade800, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label · $ageText',
                    style: textStyle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (scrapedTime != null)
                    Text(localizedDateTime(scrapedTime, locale), style: textStyle),
                  if (freshness.level == FreshnessLevel.red)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(tr('freshness_hint'), style: textStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
