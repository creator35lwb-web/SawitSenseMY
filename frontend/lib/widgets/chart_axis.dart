// Axis layout for the price history chart.
//
// Before: fl_chart labelled the padded min and max (e.g. 4633 and 5009) on top
// of the regular gridlines, so labels collided ("5009" over "5000"), and the
// last date was drawn right next to the previous one ("09-25" over "09-28").
//
// Author: SS (Claude Code), Sep 2026

import 'dart:math' as math;

/// Y-axis bounds and gridline step on round numbers, e.g. 4600 to 5000 in
/// steps of 100, so every label sits on a gridline and none collide.
class PriceAxis {
  final double min;
  final double max;
  final double interval;

  const PriceAxis(this.min, this.max, this.interval);

  /// Bounds for [values] (non-empty) with at most [maxSteps] gridline steps.
  factory PriceAxis.fromValues(Iterable<double> values, {int maxSteps = 5}) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    // Headroom so the highest and lowest points aren't drawn on the border.
    final pad = math.max((hi - lo) * 0.08, 1.0);
    const steps = [10.0, 20.0, 25.0, 50.0, 100.0, 200.0, 250.0, 500.0, 1000.0];
    final interval = steps.firstWhere(
      (s) => (hi - lo + 2 * pad) / s <= maxSteps,
      orElse: () => steps.last,
    );
    return PriceAxis(
      ((lo - pad) / interval).floorToDouble() * interval,
      ((hi + pad) / interval).ceilToDouble() * interval,
      interval,
    );
  }
}

/// Which of [count] points get a date label: evenly spaced, always the first
/// and the latest, and never two so close that they overlap.
Set<int> dateLabelIndices(int count, {int maxLabels = 4}) {
  if (count <= 0) return {};
  if (count <= maxLabels) return {for (var i = 0; i < count; i++) i};
  final step = ((count - 1) / (maxLabels - 1)).ceil();
  final last = count - 1;
  final labels = <int>{for (var i = 0; i < last; i += step) i};
  // Make room for the latest date rather than crowding it.
  labels.removeWhere((i) => i != 0 && last - i < step * 0.6);
  return labels..add(last);
}
