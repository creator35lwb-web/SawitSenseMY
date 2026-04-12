// Riverpod providers for SawitSense price data.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_data.dart';
import '../services/price_service.dart';

final priceServiceProvider = Provider<PriceService>((ref) {
  return PriceService();
});

/// Fetches latest price snapshot. Falls back to demo data on failure.
final latestPriceProvider = FutureProvider<PriceSnapshot>((ref) async {
  final service = ref.read(priceServiceProvider);
  final snapshot = await service.fetchLatest();
  if (snapshot != null && snapshot.success) {
    return snapshot;
  }
  // Fallback to demo data so the UI is always usable
  return PriceService.demoSnapshot();
});

/// Fetches 30-day historical prices. Falls back to demo data.
final historyProvider = FutureProvider<List<HistoricalPrice>>((ref) async {
  final service = ref.read(priceServiceProvider);
  final history = await service.fetchHistory(days: 30);
  if (history.isNotEmpty) {
    return history;
  }
  return PriceService.demoHistory();
});

/// Tracks whether we're showing demo data.
final isDemoProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(priceServiceProvider);
  final snapshot = await service.fetchLatest();
  return snapshot == null || !snapshot.success;
});

/// Calculator state — holds the last calculation result.
final calculatorResultProvider = StateProvider<FairPriceResult?>((ref) => null);
