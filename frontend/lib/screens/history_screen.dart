// M4: Price History Chart
//
// 30-day CPO spot price line chart using fl_chart.
//
// Patch: SS (Claude Code), Sep 2026 — axis labels no longer collide (round
// gridlines, spaced dates, room at the right edge); the curve never overshoots
// the real prices; the table lists every day and has BM/EN headers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/price_data.dart';
import '../providers/price_provider.dart';
import '../l10n/l10n_provider.dart';
import '../widgets/chart_axis.dart';
import '../widgets/language_toggle.dart';
import '../widgets/app_footer.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('history_title')),
        centerTitle: true,
        actions: const [
          LanguageToggle(),
          SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(tr('history_no_data'))),
        data: (prices) {
          if (prices.isEmpty) {
            return Center(
              child: Text(
                tr('history_no_data'),
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            // Bottom padding accounts for the persistent NavigationBar so
            // the chart + history list never hide behind it; see live-audit
            // 21 May 2026.
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.viewPaddingOf(context).bottom + 96),
            child: Column(
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
                  child: _PriceLineChart(prices: prices),
                ),
                const SizedBox(height: 24),

                // Price table below chart
                _PriceTable(prices: prices),

                const SizedBox(height: 16),
                const AppFooter(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PriceLineChart extends ConsumerWidget {
  final List<HistoricalPrice> prices;
  const _PriceLineChart({required this.prices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    if (prices.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (var i = 0; i < prices.length; i++)
        FlSpot(i.toDouble(), prices[i].cpoPrice),
    ];
    final axis = PriceAxis.fromValues(prices.map((p) => p.cpoPrice));
    final labelled = dateLabelIndices(prices.length);
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
                  value.toStringAsFixed(0),
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
                    localizedDayMonth(prices[idx].date, locale),
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
                final date = idx < prices.length
                    ? localizedDayMonth(prices[idx].date, locale)
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

class _PriceTable extends ConsumerWidget {
  final List<HistoricalPrice> prices;
  const _PriceTable({required this.prices});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(tr('history_col_date'), style: headerStyle),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(tr('history_col_cpo'),
                      style: headerStyle, textAlign: TextAlign.right),
                ),
              ],
            ),
            // Every day in the chart, newest first.
            ...prices.reversed.map(
              (p) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(p.date, style: const TextStyle(fontSize: 13)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'RM ${p.cpoPrice.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
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
