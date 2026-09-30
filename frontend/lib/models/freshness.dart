// Data freshness: the ethical framework's GREEN / AMBER / RED rule.
//
//   GREEN  updated less than 6 hours ago
//   AMBER  6 to 12 hours ago
//   RED    12 hours or more, or the update time is unknown
//
// Same thresholds as get_data_freshness() in backend/monitor/health_check.py.
//
// Author: SS (Claude Code), Sep 2026

enum FreshnessLevel { green, amber, red }

class Freshness {
  static const amberAfter = Duration(hours: 6);
  static const redAfter = Duration(hours: 12);

  final FreshnessLevel level;

  /// When the data was scraped; null if the timestamp is missing or unreadable.
  final DateTime? scrapedAt;

  /// Time since [scrapedAt]; null when that is unknown.
  final Duration? age;

  const Freshness._(this.level, this.scrapedAt, this.age);

  /// Freshness of a snapshot whose `scraped_at` is [scrapedAtIso], at [now].
  factory Freshness.of(String scrapedAtIso, DateTime now) {
    final scraped = DateTime.tryParse(scrapedAtIso);
    if (scraped == null) {
      return const Freshness._(FreshnessLevel.red, null, null);
    }
    final elapsed = now.difference(scraped);
    // A timestamp slightly in the future (clock skew) counts as "just now".
    final age = elapsed.isNegative ? Duration.zero : elapsed;
    final level = age < amberAfter
        ? FreshnessLevel.green
        : age < redAfter
            ? FreshnessLevel.amber
            : FreshnessLevel.red;
    return Freshness._(level, scraped, age);
  }
}
