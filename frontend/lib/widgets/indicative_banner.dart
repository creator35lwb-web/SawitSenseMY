// Indicative-mode banner.
//
// Surfaces the backend's `is_indicative` + `indicative_notice` signals so that
// smallholders are explicitly told when the FFB Reference Price shown is a
// SawitSense-derived value (Path C), not the authoritative MPOB FFB Reference
// Price. See ADR-001 (docs/ADR-001-mpob-data-source-change.md).
//
// Visual design: warning-orange banner with an info icon, the localized
// headline, a 1-line explanation, and a tappable "Learn more" affordance that
// links to ADR-001 on GitHub.
//
// Author: QQ (Perplexity)
// Project: SawitSenseMY, YSenseAI ecosystem

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

/// URL for the ADR explaining indicative-mode in detail (shown via copy-to-
/// clipboard since GitHub Pages builds do not bundle url_launcher).
const String _adrUrl =
    'https://github.com/creator35lwb-web/SawitSenseMY/blob/main/docs/ADR-001-mpob-data-source-change.md';

class IndicativeBanner extends ConsumerWidget {
  /// Optional override for the body text. When null, the localized default
  /// `indicative_banner_body` string is shown. The backend's
  /// `indicative_notice` is intentionally NOT shown verbatim because it is
  /// English-only and verbose; the localized version is the source of truth
  /// for what smallholders see.
  final String? overrideBody;

  /// When true, render a compact (single-line) variant suitable for the
  /// calculator screen. The dashboard uses the expanded variant.
  final bool compact;

  const IndicativeBanner({
    super.key,
    this.overrideBody,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final headline = tr('indicative_banner_headline');
    final body = overrideBody ?? tr('indicative_banner_body');
    final learnMore = tr('indicative_banner_learn_more');

    const orange = Colors.deepOrange;

    return Semantics(
      label: '$headline. $body',
      container: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: orange.shade400, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Icon(Icons.warning_amber_rounded,
                      color: orange.shade700, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: TextStyle(
                          color: orange.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 13 : 14,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: orange.shade900,
                            fontSize: 12.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: _adrUrl));
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(tr('indicative_banner_link_copied')),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: Icon(Icons.open_in_new, size: 16, color: orange.shade800),
                  label: Text(
                    learnMore,
                    style: TextStyle(
                      color: orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
