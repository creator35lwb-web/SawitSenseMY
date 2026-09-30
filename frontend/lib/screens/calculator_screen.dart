// M2: Fair Price Calculator
//
// 3-input model: Region (auto-fills Price_1%), OER%, optional Paid Price.
// Shows: Fair Price + Verdict (GREEN/AMBER/RED).
//
// Patch: SS (Claude Code), Sep 2026 — when prices can't be loaded, say so and
// ask for Price_1% instead of auto-filling demo values; "How is this
// calculated?" next to the auto-filled price; form errors in every language.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_data.dart';
import '../providers/price_provider.dart';
import '../l10n/l10n_provider.dart';
import '../widgets/verdict_badge.dart';
import '../widgets/language_menu.dart';
import '../widgets/app_footer.dart';
import '../widgets/freshness_badge.dart';
import '../widgets/indicative_banner.dart';
import '../widgets/price_method_sheet.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _price1PctController = TextEditingController();
  final _oerController = TextEditingController(text: '18');
  final _paidController = TextEditingController();
  String? _selectedRegion;
  FairPriceResult? _result;

  @override
  void dispose() {
    _price1PctController.dispose();
    _oerController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  void _onRegionSelected(String region, List<RegionalPrice> regions) {
    setState(() {
      _selectedRegion = region;
    });
    final match = regions.where((r) => r.region == region).firstOrNull;
    if (match != null) {
      _price1PctController.text = match.price1PctOer.toStringAsFixed(2);
    }
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final price1Pct = double.tryParse(_price1PctController.text);
    final oer = double.tryParse(_oerController.text);
    final paid = double.tryParse(_paidController.text);

    if (price1Pct == null || oer == null) return;

    setState(() {
      _result = FairPriceResult.calculate(
        price1PctOer: price1Pct,
        gradedOer: oer,
        paidPrice: paid,
      );
    });

    ref.read(calculatorResultProvider.notifier).state = _result;
  }

  @override
  Widget build(BuildContext context) {
    final priceAsync = ref.watch(latestPriceProvider);
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('calc_title')),
        centerTitle: true,
        actions: const [
          LanguageMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        // Bottom padding ensures the form + result card never hide behind
        // the persistent NavigationBar; see live-audit 21 May 2026.
        padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewPaddingOf(context).bottom + 96),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subtitle
              Text(
                tr('calc_subtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Indicative-mode compact banner (Path C — ADR-001).
              // Shown when the loaded snapshot is in indicative mode, because
              // the auto-filled Price_1% comes from the SawitSense-derived
              // value, not the authoritative MPOB FFB Reference Price.
              priceAsync.maybeWhen(
                data: (snapshot) => snapshot != null && snapshot.isIndicative
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: IndicativeBanner(compact: true),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),

              // Freshness of the prices the region selector auto-fills.
              priceAsync.maybeWhen(
                data: (snapshot) => snapshot == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FreshnessBadge(scrapedAt: snapshot.scrapedAt),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),

              // Region selector (only when real prices are loaded)
              priceAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const _ManualEntryNote(),
                data: (snapshot) {
                  if (snapshot == null) return const _ManualEntryNote();
                  final regions = snapshot.ffb?.regions ?? [];
                  return DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _selectedRegion,
                    decoration: InputDecoration(
                      labelText: tr('calc_region'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    items: regions
                        .map((r) => DropdownMenuItem(
                              value: r.region,
                              child: Text(localizedRegion(r.region, locale)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _onRegionSelected(val, regions);
                    },
                  );
                },
              ),
              // Where the auto-filled price comes from, with links to check it.
              priceAsync.maybeWhen(
                data: (snapshot) => snapshot != null && snapshot.isIndicative
                    ? PriceMethodLink(snapshot: snapshot)
                    : const SizedBox(height: 16),
                orElse: () => const SizedBox(height: 16),
              ),

              // Price per 1% OER
              TextFormField(
                controller: _price1PctController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('calc_price_1pct'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: tr('per_1pct'),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('validation_required');
                  if (double.tryParse(v) == null) {
                    return tr('validation_number');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // OER %
              TextFormField(
                controller: _oerController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('calc_oer'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.percent),
                  helperText: tr('calc_oer_tip'),
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr('validation_required');
                  final val = double.tryParse(v);
                  if (val == null) return tr('validation_number');
                  if (val < 1 || val > 30) return '1-30%';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Paid price (optional)
              TextFormField(
                controller: _paidController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr('calc_paid'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Calculate button
              FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_outlined),
                label: Text(
                  tr('calc_calculate'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),

              // Result
              if (_result != null) _ResultCard(result: _result!),

              const SizedBox(height: 16),
              const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown in place of the region selector when prices can't be loaded: the
/// smallholder can still enter Price_1% from a receipt or MPOB notice.
class _ManualEntryNote extends ConsumerWidget {
  const _ManualEntryNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('calc_prices_unavailable'),
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final FairPriceResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fair price
            Text(
              tr('calc_fair_price'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'RM ${result.fairPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
            ),
            Text(
              '${result.price1PctOer.toStringAsFixed(2)} x ${result.gradedOer.toStringAsFixed(1)}% OER',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 16),

            // Verdict (if paid price given)
            if (result.verdict != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              VerdictBadge(verdict: result.verdict!),
              const SizedBox(height: 8),
              Text(
                '${tr('calc_gap')}: RM ${result.gapRm?.toStringAsFixed(2)} (${result.gapPct?.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                result.verdict == 'GREEN'
                    ? tr('verdict_green')
                    : result.verdict == 'AMBER'
                        ? tr('verdict_amber')
                        : tr('verdict_red'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
