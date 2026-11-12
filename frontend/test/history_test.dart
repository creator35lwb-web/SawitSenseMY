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

  group("MPOB's daily prices by region (D26)", () {
    http.Response index() => http.Response(
        jsonEncode({
          'days': [
            {'date': _daysAgo(1), 'cpo_price': 4700.0},
          ],
          'ffb_days': [
            {
              'date': _daysAgo(40), // outside 30 days
              'prices': {'North': 47.25, 'Sabah': 41.99},
            },
            {
              'date': _daysAgo(1),
              'prices': {'North': 43.54, 'Sabah': 39.03},
            },
            {
              'date': _daysAgo(2),
              'prices': {'North': 43.35}, // a holiday in Sabah
            },
            {'date': _daysAgo(3), 'prices': {}}, // nothing to show
          ],
        }),
        200);

    test('are read oldest first, within 30 days', () async {
      final client = MockClient((request) async => index());

      final days = await PriceService(baseUrl: _base, client: client)
          .fetchFfbHistory(days: 30);

      expect(days.map((d) => d.date), [_daysAgo(2), _daysAgo(1)]);
      expect(days.last.prices, {'North': 43.54, 'Sabah': 39.03});
      expect(days.first.prices.containsKey('Sabah'), isFalse);
    });

    test('share one request with the CPO history', () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return index();
      });
      final service = PriceService(baseUrl: _base, client: client);

      final both = await Future.wait(
          [service.fetchHistory(days: 30), service.fetchFfbHistory(days: 30)]);

      expect(both.first, hasLength(1));
      expect(both.last, hasLength(2));
      expect(requests, hasLength(1));
    });

    test('a data file from before D26 gives none', () async {
      final client = MockClient((request) async => http.Response(
          jsonEncode({
            'days': [
              {'date': _daysAgo(1), 'cpo_price': 4700.0},
            ],
          }),
          200));

      final days = await PriceService(baseUrl: _base, client: client)
          .fetchFfbHistory(days: 30);

      expect(days, isEmpty);
    });

    test('a file that can\'t be read gives none, and is asked for again',
        () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return calls == 1 ? http.Response('not found', 404) : index();
      });
      final service = PriceService(baseUrl: _base, client: client);

      expect(await service.fetchFfbHistory(days: 30), isEmpty);
      expect(await service.fetchFfbHistory(days: 30), hasLength(2));
    });
  });
}
