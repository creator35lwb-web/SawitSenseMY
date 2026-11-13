// "Before you accept a price": four things to check in a dealer's offer (D31).
//
// They come from one grower's receipts over a month, and the sheet says so:
// it is what that month showed, not a rule and not a fair margin (D23). The
// example uses round figures, and no dealer, place or person is named.
//
// Author: SS (Claude Code), Nov 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

/// How many checks the guide lists: `guide_1_title` … `guide_4_body`.
const offerGuideChecks = 4;

/// Opens the guide as a bottom sheet.
void showOfferGuideSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const OfferGuideSheet(),
  );
}

/// The link that opens the guide: "Before you accept a price: 4 checks".
class OfferGuideLink extends ConsumerWidget {
  const OfferGuideLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => showOfferGuideSheet(context),
        icon: const Icon(Icons.fact_check_outlined, size: 18),
        label: Text(tr('guide_link')),
      ),
    );
  }
}

class OfferGuideSheet extends ConsumerWidget {
  const OfferGuideSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('guide_title'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(tr('guide_intro')),
            for (var i = 1; i <= offerGuideChecks; i++) ...[
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 6),
                child: Text(
                  '$i. ${tr('guide_${i}_title')}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(tr('guide_${i}_body')),
            ],
            // What this is and isn't, stated as plainly as the checks.
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('guide_limits'),
                      style:
                          TextStyle(color: Colors.grey.shade800, fontSize: 13),
                    ),
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
