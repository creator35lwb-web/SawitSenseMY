// The two forms the sales journal takes outside the app's memory (D29):
//
//   - on the phone: one JSON text in the browser's storage,
//       {"v":1,"sales":[{"date":"2026-10-23","region":"North","tonnes":5.08,
//         "price":790,"transport":23,"oer":18.25,"label":"A",
//         "mpob_price":47.87,"mpob_date":"2026-10-23"}]}
//   - as a file the reader exports: CSV with the same names as its columns,
//     which opens in Excel or Google Sheets.
//
// Both are read tolerantly: a row that doesn't make a sale is left out and
// counted, never guessed at.
//
// Author: SS (Claude Code), Nov 2026

import 'dart:convert';
import '../models/sale.dart';

/// The version written into the stored JSON.
const journalFormatVersion = 1;

/// The exported file's columns, in order.
const journalCsvColumns = [
  'date',
  'region',
  'tonnes',
  'price',
  'transport',
  'oer',
  'label',
  'mpob_price',
  'mpob_date',
];

/// What a read found: the sales it could make, and how many rows it left out.
class JournalRead {
  final List<Sale> sales;
  final int skipped;
  const JournalRead(this.sales, this.skipped);
}

/// The journal as the JSON text kept on the phone.
String encodeJournal(List<Sale> sales) => jsonEncode({
      'v': journalFormatVersion,
      'sales': [for (final sale in sales) sale.toJson()],
    });

/// The sales in a stored JSON text; none when it is missing or damaged.
JournalRead decodeJournal(String? text) {
  if (text == null || text.trim().isEmpty) return const JournalRead([], 0);
  try {
    final json = jsonDecode(text);
    final rows = json is Map ? json['sales'] : null;
    if (rows is! List) return const JournalRead([], 0);
    final sales = <Sale>[];
    var skipped = 0;
    for (final row in rows) {
      final sale =
          row is Map ? Sale.tryParse(Map<String, dynamic>.from(row)) : null;
      if (sale == null) {
        skipped++;
      } else {
        sales.add(sale);
      }
    }
    return JournalRead(sales, skipped);
  } catch (_) {
    return const JournalRead([], 0);
  }
}

String _plain(double value) {
  final s = value.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}

/// The journal as a CSV file: a header row, then one row per sale.
String journalToCsv(List<Sale> sales) {
  final lines = [journalCsvColumns.join(',')];
  for (final s in sales) {
    lines.add([
      s.date,
      s.region,
      _plain(s.tonnes),
      _plain(s.price),
      s.transport > 0 ? _plain(s.transport) : '',
      s.oer != null ? _plain(s.oer!) : '',
      s.label,
      s.mpobPrice != null ? _plain(s.mpobPrice!) : '',
      s.mpobDate ?? '',
    ].join(','));
  }
  return '${lines.join('\r\n')}\r\n';
}

/// The sales in a CSV file, or null when it isn't a journal: no header row
/// naming at least the date, region, tonnes and price.
///
/// Columns are found by name, so their order doesn't matter and extra ones
/// are ignored. A spreadsheet's habits are allowed for: a byte-order mark,
/// quoted cells, semicolons between cells, and dates rewritten as 23/10/2026.
JournalRead? journalFromCsv(String text) {
  final lines = const LineSplitter()
      .convert(text.replaceFirst('﻿', ''))
      .where((line) => line.trim().isNotEmpty)
      .toList();
  if (lines.isEmpty) return null;

  final separator = lines.first.contains(';') ? ';' : ',';
  List<String> cells(String line) => [
        for (final cell in line.split(separator))
          cell.trim().replaceAll(RegExp(r'^"|"$'), '').trim(),
      ];

  final header = [for (final name in cells(lines.first)) name.toLowerCase()];
  for (final needed in ['date', 'region', 'tonnes', 'price']) {
    if (!header.contains(needed)) return null;
  }

  final sales = <Sale>[];
  var skipped = 0;
  for (final line in lines.skip(1)) {
    final row = cells(line);
    final sale = Sale.tryParse({
      for (var i = 0; i < header.length && i < row.length; i++)
        if (journalCsvColumns.contains(header[i]) && row[i].isNotEmpty)
          header[i]: row[i],
    });
    if (sale == null) {
      skipped++;
    } else {
      sales.add(sale);
    }
  }
  return JournalRead(sales, skipped);
}
