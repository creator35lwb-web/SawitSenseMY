// "Latest from MPOB" (D18): which MPOB OER month is in today's prices and
// when it arrived, with links to MPOB's own news pages.
//
// A reader asked for the latest MPOB news (feedback, 16 Oct 2026).
// SawitSense links to MPOB's pages rather than copying the news: the pages
// stay MPOB's, always current, and never mis-summarised.
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import '../models/price_data.dart';
import 'source_link.dart';

class MpobUpdatesCard extends ConsumerWidget {
  /// The OER block behind today's prices, or null if there is none.
  final OerInfo? oer;

  const MpobUpdatesCard({super.key, required this.oer});

  /// "These prices use MPOB's OER for Sep 2026, added on 12 Oct.", without
  /// the date when it's unknown; null when there is no OER month.
  static String? oerLine(
      OerInfo? oer, AppLocale locale, String Function(String) tr) {
    final year = oer?.year;
    final month = oer?.month;
    if (year == null || month == null || month < 1 || month > 12) return null;
    final monthText = localizedMonthYear(year, month, locale);
    final since = oer?.inAppSince;
    if (since == null || DateTime.tryParse(since) == null) {
      return tr('mpob_updates_oer').replaceAll('{month}', monthText);
    }
    return tr('mpob_updates_oer_since')
        .replaceAll('{month}', monthText)
        .replaceAll('{date}', localizedDayMonth(since, locale));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final line = oerLine(oer, locale, tr);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr('mpob_updates_title'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            if (line != null) ...[
              const SizedBox(height: 8),
              Text(line),
            ],
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              children: [
                SourceLink(
                    label: tr('mpob_news'), url: mpobNewsUrl, fontSize: 14),
                SourceLink(
                    label: tr('mpob_press'), url: mpobPressUrl, fontSize: 14),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tr('mpob_links_note'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: asideFontStyle(locale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
