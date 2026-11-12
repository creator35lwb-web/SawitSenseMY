// Price data service for SawitSense.
//
// Reads the backend/data/ JSON snapshots that the deploy publishes to
// GitHub Pages:
//   https://creator35lwb-web.github.io/SawitSenseMY/data/latest.json
//
// When data can't be loaded this returns null / an empty list. It never
// substitutes demo prices: made-up numbers that look real are unsafe for a
// smallholder comparing a dealer's quote (ethical framework: Transparency).
//
// Patch: SS (Claude Code), Sep 2026 — demo data removed; history comes from
// one small history.json instead of one request per day.
// Patch: SS (Claude Code), Nov 2026 — MPOB's daily prices by region, from the
// same history.json (D26).

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class PriceService {
  /// Base URL for JSON data.
  /// In prototype: GitHub Pages serves backend/data/ as static files.
  /// Override via constructor for testing.
  final String baseUrl;

  final http.Client _client;

  PriceService({
    this.baseUrl =
        'https://creator35lwb-web.github.io/SawitSenseMY/data',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Fetch latest price snapshot.
  Future<PriceSnapshot?> fetchLatest() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/latest.json'),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PriceSnapshot.fromJson(json);
      }
      return null;
    } catch (e) {
      // Return null — UI will show "no data" state
      return null;
    }
  }

  /// Fetch historical prices for chart (last N days), oldest first.
  ///
  /// Reads history.json, one small file the backend rewrites every run. That
  /// matters on a weak rural connection: the old way made one request per
  /// day, 30 in all, including 404s for weekends. Falls back to the per-day
  /// files if the index can't be read.
  Future<List<HistoricalPrice>> fetchHistory({int days = 30}) async {
    return await _fetchHistoryIndex(days) ?? await _fetchHistoryPerDay(days);
  }

  /// MPOB's daily price per 1% OER for each region over the last [days]
  /// days, oldest first (D26). Empty when history.json can't be read or
  /// holds none.
  Future<List<FfbHistoryDay>> fetchFfbHistory({int days = 30}) async {
    try {
      final json = await _fetchIndex();
      if (json == null) return const [];
      final cutoff =
          _dateString(DateTime.now().subtract(Duration(days: days - 1)));
      final history = (json['ffb_days'] as List<dynamic>? ?? const [])
          .map((d) => FfbHistoryDay.fromJson(d as Map<String, dynamic>))
          .where((d) => d.prices.isNotEmpty && d.date.compareTo(cutoff) >= 0)
          .toList();
      history.sort((a, b) => a.date.compareTo(b.date));
      return history;
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?>? _index;

  /// history.json, or null if it can't be read. The CPO history and MPOB's
  /// share one request; a failed one is asked for again next time.
  Future<Map<String, dynamic>?> _fetchIndex() async {
    final json = await (_index ??= _requestIndex());
    if (json == null) _index = null;
    return json;
  }

  Future<Map<String, dynamic>?> _requestIndex() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/history.json'));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Entries from history.json within the last [days] days, or null if the
  /// index can't be read.
  Future<List<HistoricalPrice>?> _fetchHistoryIndex(int days) async {
    try {
      final json = await _fetchIndex();
      if (json == null) return null;
      final cutoff =
          _dateString(DateTime.now().subtract(Duration(days: days - 1)));
      final prices = (json['days'] as List<dynamic>? ?? const [])
          .map((d) => HistoricalPrice.fromHistoryEntry(d as Map<String, dynamic>))
          .where((p) => p.cpoPrice > 0 && p.date.compareTo(cutoff) >= 0)
          .toList();
      prices.sort((a, b) => a.date.compareTo(b.date));
      return prices;
    } catch (_) {
      return null;
    }
  }

  /// The pre-v0.3.4 way: one request per day for prices_YYYY-MM-DD.json.
  Future<List<HistoricalPrice>> _fetchHistoryPerDay(int days) async {
    final prices = <HistoricalPrice>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final dateStr = _dateString(now.subtract(Duration(days: i)));
      try {
        final response = await _client.get(
          Uri.parse('$baseUrl/prices_$dateStr.json'),
        );
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final hp = HistoricalPrice.fromJson(json);
          if (hp.cpoPrice > 0) {
            prices.add(hp);
          }
        }
      } catch (_) {
        // Skip missing dates (weekends, holidays, scrape failures)
      }
    }

    // Sort ascending by date for chart
    prices.sort((a, b) => a.date.compareTo(b.date));
    return prices;
  }

  static String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
