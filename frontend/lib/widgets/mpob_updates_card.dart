// "Latest from MPOB" (D18): links to MPOB's own pages: its daily FFB
// reference price PDF, its palm oil news round-up and its press releases.
//
// A reader asked for the latest MPOB news (feedback, 16 Oct 2026).
// SawitSense links to MPOB's pages rather than copying the news: the pages
// stay MPOB's, always current, and never mis-summarised. The price PDF is the
// one today's prices were read from (D22), so readers can check them.
//
// Until v0.3.17 the card also said "These prices use MPOB's OER for
// Sep 2026, added on 12 Oct." Beside a fresh price that read as out of date,
// and it wasn't true: the price per 1% OER comes from MPOC's CPO price alone.
// MPOB's OER month is shown where it is used, in "How is this calculated?"
// (D20, K24).
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import 'source_link.dart';

class MpobUpdatesCard extends ConsumerWidget {
  /// MPOB's daily FFB price PDF the prices were read from; this month's
  /// when the data doesn't give one.
  final String? ffbPdfUrl;

  const MpobUpdatesCard({super.key, this.ffbPdfUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);

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
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                SourceLink(
                    label: tr('mpob_ffb_pdf'),
                    url: ffbPdfUrl ?? mpobFfbPdfUrl(DateTime.now()),
                    fontSize: 14),
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
