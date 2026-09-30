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
// Patch: SS (Claude Code), Sep 2026 — demo data removed.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class PriceService {
  /// Base URL for JSON data.
  /// In prototype: GitHub Pages serves backend/data/ as static files.
  /// Override via constructor for testing or Firestore migration.
  final String baseUrl;

  PriceService({
    this.baseUrl =
        'https://creator35lwb-web.github.io/SawitSenseMY/data',
  });

  /// Fetch latest price snapshot.
  Future<PriceSnapshot?> fetchLatest() async {
    try {
      final response = await http.get(
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

  /// Fetch historical prices for chart (last N days).
  /// Each file is named prices_YYYY-MM-DD.json.
  Future<List<HistoricalPrice>> fetchHistory({int days = 30}) async {
    final prices = <HistoricalPrice>[];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      try {
        final response = await http.get(
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
}
