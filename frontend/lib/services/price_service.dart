// Price data service for SawitSense.
//
// Fetches data from:
//   1. GitHub Pages JSON fallback (primary for prototype)
//   2. Firestore (when configured, future)
//
// For the prototype, we read from the backend/data/ JSON files
// served via GitHub Pages at:
//   https://creator35lwb-web.github.io/SawitSenseMY/data/latest.json

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

  /// Generate demo data for when real data is unavailable.
  /// Shows realistic MPOB-like prices so users can experience the UI.
  static PriceSnapshot demoSnapshot() {
    return const PriceSnapshot(
      cpo: CpoPrice(
        date: '2025-01-10',
        priceMyrPerTonne: 4650.00,
        source: 'Demo Data',
      ),
      ffb: FfbPriceData(
        date: '2025-01-10',
        regions: [
          RegionalPrice(region: 'North', date: '2025-01-10', price1PctOer: 42.77, source: 'Demo'),
          RegionalPrice(region: 'South', date: '2025-01-10', price1PctOer: 43.12, source: 'Demo'),
          RegionalPrice(region: 'Central', date: '2025-01-10', price1PctOer: 42.95, source: 'Demo'),
          RegionalPrice(region: 'East Coast', date: '2025-01-10', price1PctOer: 41.88, source: 'Demo'),
          RegionalPrice(region: 'Sabah', date: '2025-01-10', price1PctOer: 40.65, source: 'Demo'),
          RegionalPrice(region: 'Sarawak', date: '2025-01-10', price1PctOer: 41.20, source: 'Demo'),
        ],
        cpoPrice: 4650.00,
        source: 'Demo Data',
      ),
      scrapedAt: '2025-01-10T08:30:00+08:00',
      updatedAt: '2025-01-10T08:31:00+08:00',
      success: true,
    );
  }

  /// Generate demo historical data for chart.
  static List<HistoricalPrice> demoHistory() {
    final history = <HistoricalPrice>[];
    const base = 4500.0;
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // Skip weekends
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      // Simulate realistic price movement (+-150 range)
      final variation = (i * 17 % 300) - 150;
      history.add(HistoricalPrice(
        date: dateStr,
        cpoPrice: base + variation.toDouble(),
      ));
    }
    return history;
  }
}
