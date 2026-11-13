// M3: My Sales Journal (D29)
//
// The reader's own record of each sale, set against MPOB's price for that
// day: what was kept per tonne, the OER that price paid for, and, when the
// receipt names an OER, the gap to the mill-gate value.
//
// Privacy: the sales are kept on the reader's phone only (the browser's
// storage) and leave it only as a CSV file the reader exports. No dealer's
// name is kept; a sale may carry a letter, A to F.
//
// Author: SS (Claude Code), Nov 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';
import '../models/sale.dart';
import '../providers/journal_provider.dart';
import '../services/journal_codec.dart';
import '../widgets/app_footer.dart';
import '../widgets/language_menu.dart';

/// A number as a receipt would print it: 17.25 stays 17.25, 784.0 is 784.
String _plain(double value) {
  final s = value.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

/// A sum of money: 3896.2 is "3,896.20".
String journalMoney(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  final whole = parts[0];
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '${value < 0 ? '-' : ''}$grouped.${parts[1]}';
}

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final journal = ref.watch(journalProvider);
    final sales = newestFirst(journal.sales);
    final theme = Theme.of(context);

    // Sales by month, newest month first.
    final months = <String, List<Sale>>{};
    for (final sale in sales) {
      months.putIfAbsent(sale.date.substring(0, 7), () => []).add(sale);
    }

    return Scaffold(
      appBar: AppBar(
        // Long titles shrink to fit rather than being cut off on small phones.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(tr('journal_title')),
        ),
        centerTitle: true,
        actions: const [
          LanguageMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewPaddingOf(context).bottom + 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Note(
              icon: Icons.lock_outline,
              text: tr('journal_privacy'),
              color: Colors.green,
            ),
            if (!journal.kept) ...[
              const SizedBox(height: 12),
              _Note(
                icon: Icons.warning_amber_outlined,
                text: tr('journal_not_kept'),
                color: Colors.orange,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                builder: (_) => const AddSaleSheet(),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                tr('journal_add'),
                style: const TextStyle(fontSize: 16),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            if (sales.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  tr('journal_empty'),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              _SummaryCard(summary: JournalSummary.of(sales)),
              for (final month in months.entries) ...[
                _MonthHeader(month: month.key, sales: month.value),
                for (final sale in month.value) _SaleCard(sale: sale),
              ],
            ],
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: sales.isEmpty ? null : () => _export(context, ref),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(tr('journal_export')),
                ),
                OutlinedButton.icon(
                  onPressed: () => _import(context, ref),
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(tr('journal_import')),
                ),
                if (sales.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _deleteAll(context, ref, sales.length),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(tr('journal_delete_all')),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr('journal_file_note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: asideFontStyle(locale),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  /// Saves the journal as a CSV file, oldest sale first.
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final tr = ref.read(trProvider);
    final messenger = ScaffoldMessenger.of(context);
    final sales = newestFirst(ref.read(journalProvider).sales).reversed.toList();
    final name = 'sawitsense-sales-${isoDate(ref.read(todayProvider)())}.csv';
    final saved = await ref
        .read(journalDeviceProvider)
        .saveFile(name, journalToCsv(sales));
    messenger.showSnackBar(SnackBar(
      content: Text(saved
          ? tr('journal_exported')
              .replaceAll('{file}', name)
              .replaceAll('{n}', '${sales.length}')
          : tr('journal_export_failed')),
    ));
  }

  /// Reads a CSV file the reader picks and adds the sales not already here.
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final tr = ref.read(trProvider);
    final messenger = ScaffoldMessenger.of(context);
    final text = await ref.read(journalDeviceProvider).pickFile();
    if (text == null) return;
    final read = journalFromCsv(text);
    if (read == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(tr('journal_import_failed'))));
      return;
    }
    final added = ref.read(journalProvider.notifier).addNew(read.sales);
    messenger.showSnackBar(SnackBar(
      content: Text(tr('journal_imported')
          .replaceAll('{n}', '$added')
          .replaceAll('{s}', '${read.skipped + read.sales.length - added}')),
    ));
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref, int count) async {
    final tr = ref.read(trProvider);
    final yes = await _confirm(
      context,
      tr('journal_delete_all_confirm').replaceAll('{n}', '$count'),
      tr('journal_delete_all'),
      tr('journal_cancel'),
    );
    if (yes) ref.read(journalProvider.notifier).clear();
  }
}

Future<bool> _confirm(
    BuildContext context, String question, String yes, String no) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(no),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
          child: Text(yes),
        ),
      ],
    ),
  );
  return answer ?? false;
}

/// A short notice in a tinted box: where the journal is kept, or that the
/// browser isn't keeping it.
class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;
  const _Note({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color.shade900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final JournalSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);
    final averageKept = summary.averageKept;
    final averagePaysFor = summary.averagePaysFor;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('journal_summary_title'),
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              tr('journal_summary_received')
                  .replaceAll('{rm}', journalMoney(summary.received)),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(tr('journal_summary_count')
                .replaceAll('{n}', '${summary.count}')
                .replaceAll('{t}', _plain(summary.tonnes))),
            if (averageKept != null)
              Text(tr('journal_summary_average')
                  .replaceAll('{rm}', journalMoney(averageKept))),
            if (averagePaysFor != null) ...[
              const SizedBox(height: 4),
              Text(
                tr('journal_summary_pays_for')
                    .replaceAll('{oer}', averagePaysFor.toStringAsFixed(1)),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  /// The month as "2026-10".
  final String month;
  final List<Sale> sales;
  const _MonthHeader({required this.month, required this.sales});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final summary = JournalSummary.of(sales);
    final year = int.parse(month.substring(0, 4));
    final monthNumber = int.parse(month.substring(5, 7));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedMonthYear(year, monthNumber, locale),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            tr('journal_month_total')
                .replaceAll('{n}', '${summary.count}')
                .replaceAll('{t}', _plain(summary.tonnes))
                .replaceAll('{rm}', journalMoney(summary.received)),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends ConsumerWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall;
    final paysFor = sale.paysForOer;
    final comparison = sale.comparison;
    final gapRm = comparison?.gapRm;
    final gapPct = comparison?.gapPct;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      localizedDate(sale.date, locale),
                      localizedRegion(sale.region, locale),
                      if (sale.label.isNotEmpty)
                        tr('journal_dealer').replaceAll('{label}', sale.label),
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: tr('journal_delete'),
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey.shade600),
                  onPressed: () async {
                    final yes = await _confirm(
                      context,
                      tr('journal_delete_confirm'),
                      tr('journal_delete'),
                      tr('journal_cancel'),
                    );
                    if (yes) ref.read(journalProvider.notifier).remove(sale);
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('journal_sale_sum')
                        .replaceAll('{t}', _plain(sale.tonnes))
                        .replaceAll('{kept}', _plain(sale.kept))
                        .replaceAll('{total}', journalMoney(sale.received)),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (sale.transport > 0)
                    Text(
                      tr('calc_net_price')
                          .replaceAll('{paid}', _plain(sale.price))
                          .replaceAll('{transport}', _plain(sale.transport))
                          .replaceAll('{net}', _plain(sale.kept)),
                      style: small,
                    ),
                  const SizedBox(height: 4),
                  if (paysFor != null)
                    Text(
                      tr('journal_sale_pays_for')
                          .replaceAll('{oer}', paysFor.toStringAsFixed(1))
                          .replaceAll(
                              '{price}', sale.mpobPrice!.toStringAsFixed(2))
                          .replaceAll('{date}',
                              localizedDayMonth(sale.mpobDate!, locale)),
                      style: small?.copyWith(fontWeight: FontWeight.w600),
                    )
                  else
                    Text(
                      tr('journal_sale_no_mpob'),
                      style: small?.copyWith(color: Colors.grey.shade600),
                    ),
                  if (gapRm != null && gapPct != null)
                    Text(
                      tr(gapRm < 0 ? 'journal_sale_below' : 'journal_sale_above')
                          .replaceAll('{rm}', _plain(gapRm.abs()))
                          .replaceAll('{pct}', gapPct.abs().toStringAsFixed(1))
                          .replaceAll('{oer}', _plain(sale.oer!)),
                      style: small,
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

/// The form for one sale, as a bottom sheet.
class AddSaleSheet extends ConsumerStatefulWidget {
  const AddSaleSheet({super.key});

  @override
  ConsumerState<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends ConsumerState<AddSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tonnes = TextEditingController();
  final _price = TextEditingController();
  final _transport = TextEditingController();
  final _oer = TextEditingController();
  late DateTime _date;
  String? _region;
  String _label = '';

  @override
  void initState() {
    super.initState();
    final today = ref.read(todayProvider)();
    _date = DateTime(today.year, today.month, today.day);
    // Most readers sell in one region: start from the last one used.
    final sales = ref.read(journalProvider).sales;
    if (sales.isNotEmpty) _region = sales.last.region;
  }

  @override
  void dispose() {
    _tonnes.dispose();
    _price.dispose();
    _transport.dispose();
    _oer.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final tonnes = double.tryParse(_tonnes.text);
    final price = double.tryParse(_price.text);
    if (tonnes == null || price == null || _region == null) return;

    ref.read(journalProvider.notifier).add(Sale(
          date: isoDate(_date),
          region: _region!,
          tonnes: tonnes,
          price: price,
          transport: double.tryParse(_transport.text) ?? 0,
          oer: double.tryParse(_oer.text),
          label: _label,
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);
    const number = TextInputType.numberWithOptions(decimal: true);

    String? above0(String? v) {
      if (v == null || v.isEmpty) return tr('validation_required');
      final val = double.tryParse(v);
      return val == null || val <= 0 ? tr('validation_number') : null;
    }

    return SafeArea(
      child: SingleChildScrollView(
        // Room for the phone's keyboard.
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('journal_add'),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Date of the sale: today unless the reader picks another.
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: tr('journal_date'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.event_outlined),
                  ),
                  child: Text(localizedDate(isoDate(_date), locale)),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _region,
                decoration: InputDecoration(
                  labelText: tr('calc_region'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                items: [
                  for (final region in saleRegions)
                    DropdownMenuItem(
                      value: region,
                      child: Text(localizedRegion(region, locale)),
                    ),
                ],
                validator: (v) => v == null ? tr('validation_required') : null,
                onChanged: (v) => setState(() => _region = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _tonnes,
                keyboardType: number,
                decoration: InputDecoration(
                  labelText: tr('journal_tonnes'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.scale_outlined),
                ),
                validator: above0,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _price,
                keyboardType: number,
                decoration: InputDecoration(
                  labelText: tr('journal_price'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                validator: above0,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _transport,
                keyboardType: number,
                decoration: InputDecoration(
                  labelText: tr('calc_transport'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                  helperText: tr('calc_transport_tip'),
                  helperMaxLines: 3,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final val = double.tryParse(v);
                  final price = double.tryParse(_price.text);
                  if (val == null || val < 0 || (price != null && val >= price)) {
                    return tr('validation_number');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _oer,
                keyboardType: number,
                decoration: InputDecoration(
                  labelText: tr('journal_oer'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.percent),
                  helperText: tr('journal_oer_tip'),
                  helperMaxLines: 2,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final val = double.tryParse(v);
                  if (val == null) return tr('validation_number');
                  return val < 1 || val > 30 ? '1-30%' : null;
                },
              ),
              const SizedBox(height: 16),

              // A letter for the dealer, so that no name is kept.
              Text(tr('journal_label'),
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in saleLabels)
                    ChoiceChip(
                      label: Text(label),
                      selected: _label == label,
                      showCheckmark: false,
                      onSelected: (on) =>
                          setState(() => _label = on ? label : ''),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tr('journal_label_tip'),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(tr('journal_cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700),
                      child: Text(tr('journal_save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
