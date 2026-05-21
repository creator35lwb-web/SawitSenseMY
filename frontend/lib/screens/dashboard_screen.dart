// M1: Daily Price Dashboard
//
// Shows: CPO spot price + FFB Reference Prices (6 regions)
// Zero auth, public read-only, smallholder-first design.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/price_provider.dart';
import '../l10n/l10n_provider.dart';
import '../widgets/region_price_card.dart';
import '../widgets/language_toggle.dart';
import '../widgets/feedback_button.dart';
import '../widgets/app_footer.dart';
import '../widgets/indicative_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceAsync = ref.watch(latestPriceProvider);
    final isDemoAsync = ref.watch(isDemoProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png'),
        ),
        title: Text(tr('dashboard_title')),
        centerTitle: true,
        actions: const [
          LanguageToggle(),
          SizedBox(width: 8),
        ],
      ),
      body: priceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(tr('no_data'), style: const TextStyle(fontSize: 18)),
        ),
        data: (snapshot) {
          final isDemo = isDemoAsync.valueOrNull ?? true;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Demo banner
                if (isDemo)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.amber.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('demo_banner'),
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isDemo) const SizedBox(height: 16),

                // Indicative-mode banner (Path C — ADR-001)
                if (snapshot.isIndicative) ...[
                  const IndicativeBanner(),
                  const SizedBox(height: 16),
                ],

                // CPO Spot Price card
                _CpoCard(snapshot: snapshot),
                const SizedBox(height: 20),

                // FFB Regional Prices
                Text(
                  tr('ffb_reference'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                if (snapshot.ffb != null &&
                    snapshot.ffb!.regions.isNotEmpty) ...[
                  ...snapshot.ffb!.regions.map(
                    (region) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RegionPriceCard(regionalPrice: region),
                    ),
                  ),
                ] else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(tr('no_data'))),
                    ),
                  ),

                const SizedBox(height: 16),

                // OER tip
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('calc_oer_tip'),
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Source + timestamp
                if (snapshot.updatedAt.isNotEmpty)
                  Text(
                    '${tr('last_updated')}: ${snapshot.updatedAt}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),

                const SizedBox(height: 16),

                // Feedback + Footer
                const Center(child: FeedbackButton()),
                const SizedBox(height: 8),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CpoCard extends ConsumerWidget {
  final dynamic snapshot;
  const _CpoCard({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final cpo = snapshot.cpo;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('cpo_spot_price'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  cpo != null
                      ? 'RM ${cpo.priceMyrPerTonne.toStringAsFixed(2)}'
                      : '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    tr('per_tonne'),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 14),
                  ),
                ),
              ],
            ),
            if (cpo != null) ...[
              const SizedBox(height: 8),
              Text(
                '${cpo.date}  •  ${cpo.source}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
