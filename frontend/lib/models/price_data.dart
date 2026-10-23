// Data models for SawitSense price data.
//
// Maps directly to the JSON written by backend/writer/json_writer.py:
//   - data/latest.json            -> PriceSnapshot
//   - data/prices_YYYY-MM-DD.json -> PriceSnapshot (historical)

class RegionalPrice {
  final String region;
  final String date;
  final double price1PctOer;
  final String source;
  /// True when this regional value is derived (Path C indicative pipeline),
  /// not the authoritative MPOB FFB Reference Price. See ADR-001.
  final bool isIndicative;
  /// Optional MPOB monthly OER % used in the indicative derivation.
  final double? indicativeOerPct;
  /// Indicative fair price per tonne when paired with the indicative OER.
  final double? indicativeFairPricePerTonne;
  /// MPOB's monthly average OER % for the region (`avg_oer_pct` since D22,
  /// `indicative_oer_pct` before).
  final double? avgOerPct;
  /// MPOB's note on the region's price, e.g. "Miri & Bintulu" for Sarawak.
  final String? note;

  const RegionalPrice({
    required this.region,
    required this.date,
    required this.price1PctOer,
    this.source = 'MPOB BEPI',
    this.isIndicative = false,
    this.indicativeOerPct,
    this.indicativeFairPricePerTonne,
    this.avgOerPct,
    this.note,
  });

  factory RegionalPrice.fromJson(Map<String, dynamic> json) {
    final indicativeOerPct = (json['indicative_oer_pct'] as num?)?.toDouble();
    return RegionalPrice(
      region: json['region'] as String? ?? '',
      date: json['date'] as String? ?? '',
      price1PctOer: (json['price_1pct_oer'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'MPOB BEPI',
      isIndicative: json['is_indicative'] as bool? ?? false,
      indicativeOerPct: indicativeOerPct,
      indicativeFairPricePerTonne:
          (json['indicative_fair_price_per_tonne'] as num?)?.toDouble(),
      avgOerPct: (json['avg_oer_pct'] as num?)?.toDouble() ?? indicativeOerPct,
      note: json['note'] as String?,
    );
  }
}

class CpoPrice {
  final String date;
  final double priceMyrPerTonne;
  final String source;
  /// Public page where this price can be checked (e.g. MPOC's daily prices).
  final String? sourceUrl;

  const CpoPrice({
    required this.date,
    required this.priceMyrPerTonne,
    this.source = 'MPOB BEPI',
    this.sourceUrl,
  });

  factory CpoPrice.fromJson(Map<String, dynamic> json) {
    return CpoPrice(
      date: json['date'] as String? ?? '',
      priceMyrPerTonne: (json['price_myr_per_tonne'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'MPOB BEPI',
      sourceUrl: json['source_url'] as String?,
    );
  }
}

class FfbPriceData {
  final String date;
  final List<RegionalPrice> regions;
  final double? cpoPrice;
  final String source;
  /// True when the whole FFB block is derived (Path C). See ADR-001.
  final bool isIndicative;
  /// The documented factor in Price_1% = CPO x 0.01 x factor (ADR-001).
  /// Published so anyone can redo the sum; null in older payloads.
  final double? indicativeShareFactor;
  /// MPOB's PDF the prices were read from, so readers can check them (D22).
  final String? sourceUrl;
  /// When MPOB last updated that PDF (ISO 8601, Malaysian time).
  final String? mpobLastUpdate;
  /// True when MPOB couldn't be read this run and these are the last prices.
  final bool carriedForward;

  const FfbPriceData({
    required this.date,
    required this.regions,
    this.cpoPrice,
    this.source = 'MPOB BEPI',
    this.isIndicative = false,
    this.indicativeShareFactor,
    this.sourceUrl,
    this.mpobLastUpdate,
    this.carriedForward = false,
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
      isIndicative: json['is_indicative'] as bool? ?? false,
      indicativeShareFactor:
          (json['indicative_share_factor'] as num?)?.toDouble(),
      sourceUrl: json['source_url'] as String?,
      mpobLastUpdate: json['mpob_last_update'] as String?,
      carriedForward: json['carried_forward'] as bool? ?? false,
    );
  }
}

/// Which month of MPOB's OER figures the data holds, and where to check
/// them (the payload's `oer` block). "How is this calculated?" shows both.
class OerInfo {
  final int? year;
  final int? month;
  final String source;
  /// Public MPOB page showing these figures (not the JSON API).
  final String? sourcePageUrl;

  const OerInfo({
    this.year,
    this.month,
    this.source = '',
    this.sourcePageUrl,
  });

  factory OerInfo.fromJson(Map<String, dynamic> json) {
    return OerInfo(
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
      source: json['source'] as String? ?? '',
      sourcePageUrl: json['source_page_url'] as String?,
    );
  }
}

/// Snapshot-level metadata describing the *honesty posture* of the payload.
/// When `isIndicative` is true, the UI must surface the [IndicativeBanner] so
/// smallholders are told the values are guidance, not the authoritative MPOB
/// FFB Reference Price (see ADR-001).
class PriceSnapshot {
  final CpoPrice? cpo;
  final FfbPriceData? ffb;
  final OerInfo? oer;
  final String scrapedAt;
  final String updatedAt;
  final bool success;
  /// True when the backend ran in Path C (indicative) mode.
  final bool isIndicative;
  /// Optional human-readable explanation of why the data is indicative.
  /// Populated by backend `run_scraper.py` when isIndicative is true.
  final String? indicativeNotice;
  /// Data-source version emitted by the backend orchestrator.
  final String? dataSourceVersion;
  /// Backend formula status: 'AUTHORITATIVE' or 'INDICATIVE'.
  final String? formulaStatus;

  const PriceSnapshot({
    this.cpo,
    this.ffb,
    this.oer,
    required this.scrapedAt,
    required this.updatedAt,
    required this.success,
    this.isIndicative = false,
    this.indicativeNotice,
    this.dataSourceVersion,
    this.formulaStatus,
  });

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) {
    return PriceSnapshot(
      cpo: json['cpo'] != null
          ? CpoPrice.fromJson(json['cpo'] as Map<String, dynamic>)
          : null,
      ffb: json['ffb'] != null
          ? FfbPriceData.fromJson(json['ffb'] as Map<String, dynamic>)
          : null,
      oer: json['oer'] != null
          ? OerInfo.fromJson(json['oer'] as Map<String, dynamic>)
          : null,
      scrapedAt: json['scraped_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      isIndicative: json['is_indicative'] as bool? ?? false,
      indicativeNotice: json['indicative_notice'] as String?,
      dataSourceVersion: json['data_source_version'] as String?,
      formulaStatus: json['formula_status'] as String?,
    );
  }
}

/// Fair price calculation — mirrors backend calculate_fair_price().
/// Formula: Price/mt = Price_1% x Graded_OER%
///
/// D23: no dealer margin is published, so the negotiation target is the
/// verdict's own green band, in ringgit, rather than a made-up margin.
class FairPriceResult {
  /// An offer within this % of the benchmark is GREEN; the target is its edge.
  static const greenBandPct = 5.0;


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
    // In whole cents and hundredths of a percent, so 47.82 × 17.25 = 824.895
    // rounds to 824.90 as it would by hand, not to binary's 824.89.
    final fairPrice = ((price1PctOer * 100).round() *
                (gradedOer * 100).round() /
                100)
            .round() /
        100;

    String? verdict;
    double? gapRm;
    double? gapPct;

    if (paidPrice != null && fairPrice > 0) {
      gapRm = double.parse((paidPrice - fairPrice).toStringAsFixed(2));
      gapPct = double.parse(((gapRm / fairPrice) * 100).toStringAsFixed(2));

      if (gapPct >= -greenBandPct) {
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

  /// The lowest whole-ringgit offer that is still GREEN: the benchmark less
  /// the green band, rounded to cents and then up.
  double get targetPrice =>
      ((fairPrice * (100 - greenBandPct)).round() / 100).ceilToDouble();

  /// What a quarter of a percentage point of OER is worth per tonne.
  double get valuePerQuarterOer => (price1PctOer * 25).round() / 100;

  /// How far a paid price falls short of the target; null when it doesn't,
  /// or when it is GREEN only because the target was rounded up.
  double? get shortOfTarget =>
      paidPrice != null && verdict != 'GREEN' && paidPrice! < targetPrice
      ? ((targetPrice - paidPrice!) * 100).round() / 100
      : null;
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

  /// One entry of history.json: `{"date": "2026-09-28", "cpo_price": 4664.0}`.
  factory HistoricalPrice.fromHistoryEntry(Map<String, dynamic> json) {
    return HistoricalPrice(
      date: json['date'] as String? ?? '',
      cpoPrice: (json['cpo_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
