// Under "FFB Reference Price" on the dashboard: whose price it is and for
// which day, linked to MPOB's own PDF so readers can check it, and what a
// dealer's price is compared with (D22).
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import '../models/price_data.dart';
import 'price_method_sheet.dart';
import 'source_link.dart';

class FfbSourceLine extends ConsumerWidget {
  final PriceSnapshot snapshot;

  /// The snapshot's MPOB prices.
  final FfbPriceData ffb;

  const FfbSourceLine({super.key, required this.snapshot, required this.ffb});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SourceLink(
            label: tr('ffb_official_source')
                .replaceAll('{date}', localizedDate(ffb.date, locale)),
            url: ffb.sourceUrl ?? mpobFfbPdfUrl(DateTime.now()),
            fontSize: 13,
          ),
          const SizedBox(height: 2),
          Text(
            tr('dealer_note'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          PriceMethodLink(snapshot: snapshot),
        ],
      ),
    );
  }
}
