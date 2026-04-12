/// Data models for SawitSense price data.
///
/// Maps directly to the JSON schema written by backend/writer/firestore_writer.py:
///   - sawitsense_latest/current -> PriceSnapshot
///   - sawitsense_prices/{date}  -> PriceSnapshot (historical)

class RegionalPrice {
  final String region;
  final String date;
  final double price1PctOer;
  final String source;

  const RegionalPrice({
    required this.region,
    required this.date,
    required this.price1PctOer,
    this.source = 'MPOB BEPI',
  });

  factory RegionalPrice.fromJson(Map<String, dynamic> json) {
    return RegionalPrice(
      region: json['region'] as String? ?? '',
      date: json['date'] as String? ?? '',
      price1PctOer: (json['price_1pct_oer'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'MPOB BEPI',
    );
  }
}

class CpoPrice {
  final String date;
  final double priceMyrPerTonne;
  final String source;

  const CpoPrice({
    required this.date,
    required this.priceMyrPerTonne,
    this.source = 'MPOB BEPI',
  });

  factory CpoPrice.fromJson(Map<String, dynamic> json) {
    return CpoPrice(
      date: json['date'] as String? ?? '',
      priceMyrPerTonne: (json['price_myr_per_tonne'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'MPOB BEPI',
    );
  }
}

class FfbPriceData {
  final String date;
  final List<RegionalPrice> regions;
  final double? cpoPrice;
  final String source;

  const FfbPriceData({
    required this.date,
    required this.regions,
    this.cpoPrice,
    this.source = 'MPOB BEPI',
  });

  factory FfbPriceData.fromJson(Map<String, dynamic> json) {
    final regionsList = (json['regions'] as List<dynamic>?)
            ?.map((r) => RegionalPrice.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];
    return FfbPriceData(
      date: json['date'] as String? ?? '',
      regions: regionsList,
      cpoPrice: (json['cpo_price'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'MPOB BEPI',
    );
  }
}

class PriceSnapshot {
  final CpoPrice? cpo;
  final FfbPriceData? ffb;
  final String scrapedAt;
  final String updatedAt;
  final bool success;

  const PriceSnapshot({
    this.cpo,
    this.ffb,
    required this.scrapedAt,
    required this.updatedAt,
    required this.success,
  });

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) {
    return PriceSnapshot(
      cpo: json['cpo'] != null
          ? CpoPrice.fromJson(json['cpo'] as Map<String, dynamic>)
          : null,
      ffb: json['ffb'] != null
          ? FfbPriceData.fromJson(json['ffb'] as Map<String, dynamic>)
          : null,
      scrapedAt: json['scraped_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      success: json['success'] as bool? ?? false,
    );
  }
}

/// Fair price calculation — mirrors backend calculate_fair_price().
/// Formula: Price/mt = Price_1% x Graded_OER%
class FairPriceResult {
  final double price1PctOer;
  final double gradedOer;
  final double fairPrice;
  final double? paidPrice;
  final String? verdict;
  final double? gapRm;
  final double? gapPct;

  FairPriceResult({
    required this.price1PctOer,
    required this.gradedOer,
    required this.fairPrice,
    this.paidPrice,
    this.verdict,
    this.gapRm,
    this.gapPct,
  });

  factory FairPriceResult.calculate({
    required double price1PctOer,
    required double gradedOer,
    double? paidPrice,
  }) {
    final fairPrice =
        double.parse((price1PctOer * gradedOer).toStringAsFixed(2));

    String? verdict;
    double? gapRm;
    double? gapPct;

    if (paidPrice != null && fairPrice > 0) {
      gapRm = double.parse((paidPrice - fairPrice).toStringAsFixed(2));
      gapPct = double.parse(((gapRm! / fairPrice) * 100).toStringAsFixed(2));

      if (gapPct! >= -5) {
        verdict = 'GREEN';
      } else if (gapPct >= -15) {
        verdict = 'AMBER';
      } else {
        verdict = 'RED';
      }
    }

    return FairPriceResult(
      price1PctOer: price1PctOer,
      gradedOer: gradedOer,
      fairPrice: fairPrice,
      paidPrice: paidPrice,
      verdict: verdict,
      gapRm: gapRm,
      gapPct: gapPct,
    );
  }
}

/// Historical price entry for chart data.
class HistoricalPrice {
  final String date;
  final double cpoPrice;

  const HistoricalPrice({required this.date, required this.cpoPrice});

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) {
    final cpo = json['cpo'] as Map<String, dynamic>?;
    return HistoricalPrice(
      date: cpo?['date'] as String? ?? json['date'] as String? ?? '',
      cpoPrice: (cpo?['price_myr_per_tonne'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
