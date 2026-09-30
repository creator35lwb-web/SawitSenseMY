// History loads from one small history.json instead of one request per day,
// and falls back to the per-day files when the index can't be read.
//
// Author: SS (Claude Code), Sep 2026

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sawitsense_my/services/price_service.dart';

const _base = 'https://example.test/data';

String _daysAgo(int n) {
  final d = DateTime.now().subtract(Duration(days: n));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  test('reads the one-file history index: one request, oldest first', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/history.json')) {
        return http.Response(
            jsonEncode({
              'days': [
                {'date': _daysAgo(40), 'cpo_price': 4500.0}, // outside 30 days
                {'date': _daysAgo(1), 'cpo_price': 4700.0},
                {'date': _daysAgo(2), 'cpo_price': 4664.0},
              ],
            }),
            200);
      }
      return http.Response('not found', 404);
    });

    final history =
        await PriceService(baseUrl: _base, client: client).fetchHistory(days: 30);

    expect(history.map((h) => h.date), [_daysAgo(2), _daysAgo(1)]);
    expect(history.map((h) => h.cpoPrice), [4664.0, 4700.0]);
    expect(requests, hasLength(1));
  });

  test('falls back to one request per day when the index is missing', () async {
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/prices_${_daysAgo(1)}.json')) {
        return http.Response(
            jsonEncode({
              'cpo': {'date': _daysAgo(1), 'price_myr_per_tonne': 4664.0},
            }),
            200);
      }
      return http.Response('not found', 404);
    });

    final history =
        await PriceService(baseUrl: _base, client: client).fetchHistory(days: 5);

    expect(history.single.cpoPrice, 4664.0);
    expect(requests, hasLength(6)); // the index, then 5 days
  });
}
