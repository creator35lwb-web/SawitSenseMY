// M3: My Sales Journal (D29) — one sale, and the sums the journal shows.
//
// A sale is the reader's own record. It is kept on their phone only (see
// services/journal_store_web.dart) and leaves it only as a file the reader
// exports. No dealer's name is kept: a sale may carry a letter the reader
// chooses, A to F.
//
// Author: SS (Claude Code), Nov 2026

import 'price_data.dart';

/// MPOB's regions, as the data names them, in the order MPOB lists them.
const saleRegions = [
  'North',
  'South',
  'Central',
  'East Coast',
  'Sabah',
  'Sarawak',
];

/// The letters a reader can give a dealer. Letters, so that no name is kept.
const saleLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

/// How far back to look for MPOB's price when a sale falls on a day without
/// one (a weekend or a holiday): the last trading day, within a week.
const _lookBackDays = 7;

double _cents(double value) => (value * 100).round() / 100;

class Sale {
  /// The day of the sale, as "2026-10-23".
  final String date;

  /// The region, as the data names it ("North", "East Coast", ...).
  final String region;
  final double tonnes;

  /// The price the dealer named, RM per tonne.
  final double price;

  /// Transport the dealer took off, RM per tonne; 0 when it was inside the
  /// price.
  final double transport;

  /// The OER the dealer wrote on the receipt, in %, if any.
  final double? oer;

  /// A letter the reader chose for the dealer, or empty.
  final String label;

  /// MPOB's price per 1% OER for the region, kept with the sale so that it
  /// can still be compared once that day has left the app's history.
  final double? mpobPrice;

  /// The day [mpobPrice] is for: the sale's day, or the last trading day
  /// before it.
  final String? mpobDate;

  const Sale({
    required this.date,
    required this.region,
    required this.tonnes,
    required this.price,
    this.transport = 0,
    this.oer,
    this.label = '',
    this.mpobPrice,
    this.mpobDate,
  });

  /// What the reader kept per tonne: the price less any transport.
  double get kept => _cents(price - transport);

  /// What the reader received for the load.
  double get received => _cents(kept * tonnes);

  /// The OER the price paid for at MPOB's price (D27); null without one.
  double? get paysForOer =>
      mpobPrice != null && mpobPrice! > 0 ? kept / mpobPrice! : null;

  /// The sale measured against MPOB's mill-gate value at the receipt's OER;
  /// null when the receipt has no OER or MPOB's price isn't known.
  FairPriceResult? get comparison => oer != null && mpobPrice != null
      ? FairPriceResult.calculate(
          price1PctOer: mpobPrice!, gradedOer: oer!, paidPrice: kept)
      : null;

  /// This sale with MPOB's price for its region and day, from [history].
  ///
  /// While the day is in [history] the sale follows it: a sale entered on
  /// the morning of its day is first set against the last trading day's
  /// price, and moves to its own day's once MPOB publishes it. When
  /// [history] no longer holds the day, the price kept with the sale stays.
  Sale withMpobPrice(List<FfbHistoryDay> history) {
    final found = mpobPriceFor(history, region, date);
    if (found == null) return this;
    if (found.price == mpobPrice && found.date == mpobDate) return this;
    // Never step back to an earlier day than the one already kept.
    if (mpobDate != null && found.date.compareTo(mpobDate!) < 0) return this;
    return Sale(
      date: date,
      region: region,
      tonnes: tonnes,
      price: price,
      transport: transport,
      oer: oer,
      label: label,
      mpobPrice: found.price,
      mpobDate: found.date,
    );
  }

  /// True when [other] records the same sale; MPOB's price is not part of
  /// what the reader entered, so it is not compared.
  bool sameSaleAs(Sale other) =>
      date == other.date &&
      region == other.region &&
      tonnes == other.tonnes &&
      price == other.price &&
      transport == other.transport &&
      oer == other.oer &&
      label == other.label;

  /// As stored on the phone and as the columns of an exported file.
  Map<String, dynamic> toJson() => {
        'date': date,
        'region': region,
        'tonnes': tonnes,
        'price': price,
        if (transport > 0) 'transport': transport,
        if (oer != null) 'oer': oer,
        if (label.isNotEmpty) 'label': label,
        if (mpobPrice != null) 'mpob_price': mpobPrice,
        if (mpobDate != null) 'mpob_date': mpobDate,
      };

  /// A sale from stored or imported values, or null when they don't make
  /// one: a date that isn't a date, an unknown region, a weight or price that
  /// isn't above zero, transport that takes the whole price, an OER outside
  /// 1–30%.
  static Sale? tryParse(Map<String, dynamic> json) {
    final date = normaliseDate('${json['date'] ?? ''}');
    final region = _knownRegion('${json['region'] ?? ''}');
    final tonnes = _number(json['tonnes']);
    final price = _number(json['price']);
    final transport = _number(json['transport']) ?? 0;
    final oer = _number(json['oer']);
    final label = '${json['label'] ?? ''}'.trim().toUpperCase();
    final mpobPrice = _number(json['mpob_price']);
    final mpobDate = normaliseDate('${json['mpob_date'] ?? ''}');

    if (date == null || region == null) return null;
    if (tonnes == null || tonnes <= 0 || price == null || price <= 0) {
      return null;
    }
    if (transport < 0 || transport >= price) return null;
    if (oer != null && (oer < 1 || oer > 30)) return null;
    final known = mpobPrice != null && mpobPrice > 0 && mpobDate != null;

    return Sale(
      date: date,
      region: region,
      tonnes: tonnes,
      price: price,
      transport: transport,
      oer: oer,
      // Anything but one of the letters is dropped, so no name gets in.
      label: saleLabels.contains(label) ? label : '',
      mpobPrice: known ? mpobPrice : null,
      mpobDate: known ? mpobDate : null,
    );
  }
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  // A spreadsheet set to another locale may write 5,08 for 5.08.
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
  return null;
}

String? _knownRegion(String name) {
  final wanted = name.trim().toLowerCase();
  for (final region in saleRegions) {
    if (region.toLowerCase() == wanted) return region;
  }
  return null;
}

/// "2026-10-23" from "2026-10-23", or from "23/10/2026" as a spreadsheet may
/// rewrite it (day first, as dates are written in Malaysia). Null when
/// [text] is neither, or isn't a real day.
String? normaliseDate(String text) {
  final t = text.trim();
  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(t);
  final dayFirst = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$').firstMatch(t);
  final int year, month, day;
  if (iso != null) {
    year = int.parse(iso[1]!);
    month = int.parse(iso[2]!);
    day = int.parse(iso[3]!);
  } else if (dayFirst != null) {
    day = int.parse(dayFirst[1]!);
    month = int.parse(dayFirst[2]!);
    year = int.parse(dayFirst[3]!);
  } else {
    return null;
  }
  final d = DateTime(year, month, day);
  // DateTime rolls 31 June over to 1 July; that isn't a date anyone meant.
  if (d.year != year || d.month != month || d.day != day) return null;
  return isoDate(d);
}

/// A day as "2026-10-23".
String isoDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// MPOB's price per 1% OER for [region] on [date], or on the last trading
/// day before it within a week (a Saturday sale is set against Friday's
/// price). Null when [history] holds none.
({double price, String date})? mpobPriceFor(
    List<FfbHistoryDay> history, String region, String date) {
  final day = DateTime.tryParse(date);
  if (day == null) return null;
  final earliest = isoDate(day.subtract(const Duration(days: _lookBackDays)));
  ({double price, String date})? best;
  for (final h in history) {
    final price = h.prices[region];
    if (price == null || price <= 0) continue;
    if (h.date.compareTo(date) > 0 || h.date.compareTo(earliest) < 0) continue;
    if (best == null || h.date.compareTo(best.date) > 0) {
      best = (price: price, date: h.date);
    }
  }
  return best;
}

/// The journal's totals over [sales].
class JournalSummary {
  final int count;
  final double tonnes;

  /// What was received in all, RM.
  final double received;

  /// The price kept per tonne, averaged by weight.
  final double? averageKept;

  /// The OER the prices paid for, averaged by weight over the sales that
  /// have MPOB's price; null when none has.
  final double? averagePaysFor;

  const JournalSummary({
    required this.count,
    required this.tonnes,
    required this.received,
    this.averageKept,
    this.averagePaysFor,
  });

  factory JournalSummary.of(Iterable<Sale> sales) {
    var count = 0;
    var tonnes = 0.0;
    var received = 0.0;
    var comparedTonnes = 0.0;
    var paysForByTonnes = 0.0;
    for (final sale in sales) {
      count++;
      tonnes += sale.tonnes;
      received += sale.received;
      final paysFor = sale.paysForOer;
      if (paysFor != null) {
        comparedTonnes += sale.tonnes;
        paysForByTonnes += paysFor * sale.tonnes;
      }
    }
    return JournalSummary(
      count: count,
      tonnes: _cents(tonnes),
      received: _cents(received),
      averageKept: tonnes > 0 ? received / tonnes : null,
      averagePaysFor:
          comparedTonnes > 0 ? paysForByTonnes / comparedTonnes : null,
    );
  }
}

/// Newest first; sales on the same day keep the order they were entered in.
List<Sale> newestFirst(Iterable<Sale> sales) {
  final indexed = sales.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final byDate = b.value.date.compareTo(a.value.date);
    return byDate != 0 ? byDate : a.key.compareTo(b.key);
  });
  return [for (final e in indexed) e.value];
}
