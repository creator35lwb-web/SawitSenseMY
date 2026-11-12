// M4: Price History
//
// Two 30-day histories, as line charts with fl_chart and a table under each:
//   - MPOB's daily price per 1% OER for the reader's region (D26), the price
//     the dashboard and the calculator use;
//   - MPOC's daily CPO price.
//
// Patch: SS (Claude Code), Sep 2026 — axis labels no longer collide (round
// gridlines, spaced dates, room at the right edge); the curve never overshoots
// the real prices; the table lists every day and has BM/EN headers.
// Patch: SS (Claude Code), Nov 2026 — MPOB's price by region (D26). Until
// then the tab showed CPO only, which ended days before the dashboard's
// prices whenever MPOC was behind.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/links.dart';
import '../models/price_data.dart';
import '../providers/price_provider.dart';
import '../l10n/l10n_provider.dart';
import '../widgets/chart_axis.dart';
import '../widgets/language_menu.dart';
import '../widgets/app_footer.dart';
import '../widgets/source_link.dart';

/// Which history the tab shows.
enum HistorySeries { mpob, cpo }

/// The reader's choice of history; MPOB's price unless they pick CPO.
final historySeriesProvider =
    StateProvider<HistorySeries>((ref) => HistorySeries.mpob);

/// The region whose MPOB price is charted; the first one until the reader
/// picks another. Kept while the app is open, never stored.
final historyRegionProvider = StateProvider<String?>((ref) => null);

/// MPOB's regions in the order MPOB lists them.
const _regionOrder = [
  'North',
  'South',
  'Central',
  'East Coast',
  'Sabah',
  'Sarawak',
];

/// One point of a history: a day and its price.
class _Point {
  final String date;
  final double value;
  const _Point(this.date, this.value);
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cpoAsync = ref.watch(historyProvider);
    final ffbAsync = ref.watch(ffbHistoryProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        // Long titles shrink to fit rather than being cut off on small phones.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(tr('history_title')),
        ),
        centerTitle: true,
        actions: const [
          LanguageMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: _body(context, ref, cpoAsync, ffbAsync),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<HistoricalPrice>> cpoAsync,
    AsyncValue<List<FfbHistoryDay>> ffbAsync,
  ) {
    final tr = ref.watch(trProvider);
    if (cpoAsync.isLoading || ffbAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    // A history that failed to load is treated as empty.
    final cpo = cpoAsync.asData?.value ?? const <HistoricalPrice>[];
    final ffb = ffbAsync.asData?.value ?? const <FfbHistoryDay>[];
    if (cpo.isEmpty && ffb.isEmpty) {
      return Center(
        child: Text(
          tr('history_no_data'),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // Only the histories that have data can be chosen.
    final available = [
      if (ffb.isNotEmpty) HistorySeries.mpob,
      if (cpo.isNotEmpty) HistorySeries.cpo,
    ];
    final chosen = ref.watch(historySeriesProvider);
    final series = available.contains(chosen) ? chosen : available.first;

    return SingleChildScrollView(
      // Bottom padding accounts for the persistent NavigationBar so
      // the chart + history list never hide behind it; see live-audit
      // 21 May 2026.
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewPaddingOf(context).bottom + 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (available.length > 1) ...[
            Center(
              child: SegmentedButton<HistorySeries>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: HistorySeries.mpob,
                    label: Text(tr('history_series_mpob')),
                  ),
                  ButtonSegment(
                    value: HistorySeries.cpo,
                    label: Text(tr('history_series_cpo')),
                  ),
                ],
                selected: {series},
                onSelectionChanged: (selection) => ref
                    .read(historySeriesProvider.notifier)
                    .state = selection.first,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (series == HistorySeries.mpob)
            _MpobHistory(days: ffb)
          else
            _CpoHistory(prices: cpo),
          const SizedBox(height: 16),
          const AppFooter(),
        ],
      ),
    );
  }
}

/// MPOB's price per 1% OER for one region: region chips, chart, table, and
/// a link to MPOB's own PDF.
class _MpobHistory extends ConsumerWidget {
  final List<FfbHistoryDay> days;
  const _MpobHistory({required this.days});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final locale = ref.watch(localeProvider);

    final present = {for (final day in days) ...day.prices.keys};
    final regions = [
      ..._regionOrder.where(present.contains),
      ...present.where((r) => !_regionOrder.contains(r)),
    ];
    if (regions.isEmpty) return const SizedBox.shrink();
    final chosen = ref.watch(historyRegionProvider);
    final region = regions.contains(chosen) ? chosen! : regions.first;

    // A region on holiday on a day has no price that day, so no point.
    final points = [
      for (final day in days)
        if (day.prices[region] != null) _Point(day.date, day.prices[region]!),
    ];
    final latest = days.last.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('history_ffb_subtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final r in regions)
              ChoiceChip(
                label: Text(localizedRegion(r, locale)),
                selected: r == region,
                showCheckmark: false,
                onSelected: (_) =>
                    ref.read(historyRegionProvider.notifier).state = r,
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _PriceLineChart(points: points, minStep: 0.5),
        ),
        const SizedBox(height: 24),
        _PriceTable(
          points: points,
          valueHeader: tr('history_col_ffb'),
          changeHeader: tr('history_col_change'),
        ),
        const SizedBox(height: 8),
        Text(
          tr('history_ffb_note'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SourceLink(
            label: tr('ffb_official_source')
                .replaceAll('{date}', localizedDate(latest, locale)),
            url: mpobFfbPdfUrlForDay(latest),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// MPOC's daily CPO price: chart and table.
class _CpoHistory extends ConsumerWidget {
  final List<HistoricalPrice> prices;
  const _CpoHistory({required this.prices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final points = [for (final p in prices) _Point(p.date, p.cpoPrice)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('history_subtitle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 300,
          child: _PriceLineChart(points: points),
        ),
        const SizedBox(height: 24),
        _PriceTable(points: points, valueHeader: tr('history_col_cpo')),
      ],
    );
  }
}

class _PriceLineChart extends ConsumerWidget {
  final List<_Point> points;

  /// The smallest gridline step; see [PriceAxis.fromValues].
  final double minStep;

  const _PriceLineChart({required this.points, this.minStep = 10});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    if (points.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final axis =
        PriceAxis.fromValues(points.map((p) => p.value), minStep: minStep);
    // Whole ringgit on the axis, unless the gridlines are 50 sen apart.
    final axisDecimals = axis.interval < 1 ? 1 : 0;
    final labelled = dateLabelIndices(points.length);
    final labelStyle = TextStyle(fontSize: 11, color: Colors.grey.shade600);

    return LineChart(
      LineChartData(
        minY: axis.min,
        maxY: axis.max,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: axis.interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: axis.interval,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toStringAsFixed(axisDecimals),
                  style: labelStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if ((value - idx).abs() > 0.01 || !labelled.contains(idx)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    localizedDayMonth(points[idx].date, locale),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
          // Empty space on the right keeps the latest point and its date
          // clear of the screen edge.
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) => const SizedBox.shrink(),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
            left: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            // Never draw the line above or below the real prices between
            // two days: the chart must not show prices that never happened.
            preventCurveOverShooting: true,
            color: Colors.green.shade700,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: Colors.green.shade700,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.shade100.withValues(alpha: 0.4),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final date = idx < points.length
                    ? localizedDayMonth(points[idx].date, locale)
                    : '';
                return LineTooltipItem(
                  'RM ${spot.y.toStringAsFixed(2)}\n$date',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// How a price moved from the day before in the table, e.g. "+0.35",
/// "−0.71" or "0.00"; a dash for the first day, which has none before it.
String priceChangeLabel(double? previous, double value) {
  if (previous == null) return '–';
  final cents = ((value - previous) * 100).round();
  if (cents == 0) return '0.00';
  final amount = (cents.abs() / 100).toStringAsFixed(2);
  return cents > 0 ? '+$amount' : '−$amount';
}

class _PriceTable extends ConsumerWidget {
  final List<_Point> points;
  final String valueHeader;

  /// The heading of the change-from-the-day-before column; no such column
  /// when null.
  final String? changeHeader;

  const _PriceTable({
    required this.points,
    required this.valueHeader,
    this.changeHeader,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
    );
    Widget header(String text, {TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: headerStyle, textAlign: align),
        );
    Widget cell(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: child,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: {
            0: const FlexColumnWidth(2),
            1: const FlexColumnWidth(2),
            if (changeHeader != null) 2: const FlexColumnWidth(1.4),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              children: [
                header(tr('history_col_date')),
                header(valueHeader, align: TextAlign.right),
                if (changeHeader != null)
                  header(changeHeader!, align: TextAlign.right),
              ],
            ),
            // Every day in the chart, newest first.
            for (var i = points.length - 1; i >= 0; i--)
              TableRow(
                children: [
                  cell(Text(points[i].date,
                      style: const TextStyle(fontSize: 13))),
                  cell(Text(
                    'RM ${points[i].value.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  )),
                  if (changeHeader != null)
                    cell(Text(
                      priceChangeLabel(
                          i > 0 ? points[i - 1].value : null, points[i].value),
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
