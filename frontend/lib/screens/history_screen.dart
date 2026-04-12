// M4: Price History Chart
//
// 30-day CPO spot price line chart using fl_chart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/price_provider.dart';
import '../l10n/l10n_provider.dart';
import '../widgets/language_toggle.dart';

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
            padding: const EdgeInsets.all(16),
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
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PriceLineChart extends StatelessWidget {
  final List prices;
  const _PriceLineChart({required this.prices});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < prices.length; i++) {
      spots.add(FlSpot(i.toDouble(), prices[i].cpoPrice));
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - yPadding,
        maxY: maxY + yPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) > 0 ? (maxY - minY) / 4 : 100,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (prices.length / 5).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= prices.length) {
                  return const SizedBox.shrink();
                }
                final date = prices[idx].date;
                // Show just MM-DD
                final short =
                    date.length >= 10 ? date.substring(5, 10) : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    short,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
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
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final date =
                    idx < prices.length ? prices[idx].date : '';
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

class _PriceTable extends StatelessWidget {
  final List prices;
  const _PriceTable({required this.prices});

  @override
  Widget build(BuildContext context) {
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
                  child: Text('Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('CPO (RM/tonne)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            ...prices.reversed.take(10).map(
                  (p) => TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(p.date,
                            style: const TextStyle(fontSize: 13)),
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
