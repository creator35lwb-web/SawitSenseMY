// Riverpod providers for SawitSense price data.
//
// Patch: SS (Claude Code), Sep 2026 — no demo fallback. When real data can't
// be loaded the providers say so (null / empty list) and the screens show an
// honest "unavailable" state instead of made-up prices.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_data.dart';
import '../services/price_service.dart';

final priceServiceProvider = Provider<PriceService>((ref) {
  return PriceService();
});

/// Latest price snapshot, or null when it can't be loaded (network error,
/// missing file, or a snapshot the backend marked unsuccessful).
final latestPriceProvider = FutureProvider<PriceSnapshot?>((ref) async {
  final service = ref.read(priceServiceProvider);
  final snapshot = await service.fetchLatest();
  if (snapshot != null && snapshot.success) {
    return snapshot;
  }
  return null;
});

/// Real 30-day history; empty when none can be loaded.
final historyProvider = FutureProvider<List<HistoricalPrice>>((ref) async {
  final service = ref.read(priceServiceProvider);
  return service.fetchHistory(days: 30);
});

/// Calculator state — holds the last calculation result.
final calculatorResultProvider = StateProvider<FairPriceResult?>((ref) => null);
