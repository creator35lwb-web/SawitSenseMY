// "Where these prices come from": MPOB's daily reference price for each
// region, with a link to MPOB's own PDF, each region's MPOB OER, and what a
// dealer's price is compared with (D22).
//
// A snapshot from before D22 holds SawitSense's estimate instead. For that
// the sheet keeps its earlier form, "How is this calculated?": the estimate
// as a sum anyone can redo, and why all six regions show the same price.
//
// Author: SS (Claude Code), Sep 2026
// Patch: SS (Claude Code), Oct 2026 — MPOB's official prices (D22).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import '../models/price_data.dart';
import 'source_link.dart';

/// Opens the method explanation for [snapshot] as a bottom sheet.
void showPriceMethodSheet(BuildContext context, PriceSnapshot snapshot) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PriceMethodSheet(snapshot: snapshot),
  );
}

/// The link that opens the method sheet: "Where do these prices come
/// from?", or "How is this calculated?" for an estimate.
class PriceMethodLink extends ConsumerWidget {
  final PriceSnapshot snapshot;

  const PriceMethodLink({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showPriceMethodSheet(context, snapshot),
        icon: const Icon(Icons.help_outline, size: 18),
        label: Text(tr(
            snapshot.isIndicative ? 'method_link' : 'method_link_official')),
      ),
    );
  }
}

class PriceMethodSheet extends ConsumerWidget {
  final PriceSnapshot snapshot;

  const PriceMethodSheet({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);

    final cpo = snapshot.cpo;
    final cpoUrl = cpo?.sourceUrl;
    final regions = snapshot.ffb?.regions ?? const <RegionalPrice>[];
    // MPOB's own prices (D22); null for an estimate from before D22.
    final official = snapshot.isIndicative ? null : snapshot.ffb;
    final factor = snapshot.ffb?.indicativeShareFactor;
    final price1Pct = regions.isNotEmpty ? regions.first.price1PctOer : null;
    final oerUrl = snapshot.oer?.sourcePageUrl;
    final oerYear = snapshot.oer?.year;
    final oerMonth = snapshot.oer?.month;
    final oerPeriod = (oerYear != null && oerMonth != null)
        ? localizedMonthYear(oerYear, oerMonth, locale)
        : null;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(
            text,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr(official != null ? 'method_title_official' : 'method_title'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            if (official != null) ...[
              // 1. MPOB's own price, and where to check it.
              heading('1. ${tr('method_official_step1_title')}, '
                  '${localizedDate(official.date, locale)}'),
              Text(tr('method_official_step1_body')),
              SourceLink(
                label: tr('mpob_ffb_pdf'),
                url: official.sourceUrl ?? mpobFfbPdfUrl(DateTime.now()),
              ),
              if (regions.any((r) => r.note == 'Miri & Bintulu')) ...[
                const SizedBox(height: 6),
                Text(tr('method_sarawak_note')),
              ],
            ] else ...[
              // 1. The national price per 1% OER, as a sum anyone can redo.
              heading('1. ${tr('method_step1_title')}'),
              if (cpo != null && factor != null && price1Pct != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RM ${cpo.priceMyrPerTonne.toStringAsFixed(2)} × 0.01 × '
                    '$factor = RM ${price1Pct.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(tr('method_step1_same')),
              if (cpo != null && cpoUrl != null)
                SourceLink(
                  label: '${tr('method_cpo_source')} (${cpo.date})',
                  url: cpoUrl,
                ),
              SourceLink(label: tr('method_factor_source'), url: adrUrl),
            ],

            // 2. MPOB's average OER in each region, to compare with your grade.
            heading(oerPeriod == null
                ? '2. ${tr('method_step2_title')}'
                : '2. ${tr('method_step2_title')}, $oerPeriod'),
            for (final r in regions)
              if (r.avgOerPct != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(localizedRegion(r.region, locale))),
                      Text(
                        '${r.avgOerPct!.toStringAsFixed(2)}%',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 6),
            Text(tr('method_step2_note')),
            if (oerUrl != null)
              SourceLink(
                label: oerPeriod == null
                    ? tr('method_oer_source')
                    : tr('method_oer_source_month')
                        .replaceAll('{month}', oerPeriod),
                url: oerUrl,
              ),

            // 3. The smallholder's own number.
            heading('3. ${tr('method_step3_title')}'),
            Text(tr('method_step3_body')),
            if (official != null) ...[
              const SizedBox(height: 6),
              Text(tr('dealer_note')),
            ] else ...[
              // Why an estimate from before D22 is indicative, stated plainly.
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 18, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr('method_official_note'),
                        style: TextStyle(
                            color: Colors.orange.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SourceLink(label: tr('open_data'), url: openDataUrl),
          ],
        ),
      ),
    );
  }
}
