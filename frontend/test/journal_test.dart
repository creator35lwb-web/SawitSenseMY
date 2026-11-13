// My Sales Journal (D29): each sale is set against MPOB's price for its day;
// the journal is kept on the phone as one JSON text and leaves it only as a
// CSV file the reader exports; no dealer's name gets in; and the screen works
// in every language.
//
// Author: SS (Claude Code), Nov 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawitsense_my/l10n/app_en.dart';
import 'package:sawitsense_my/l10n/l10n_provider.dart';
import 'package:sawitsense_my/models/price_data.dart';
import 'package:sawitsense_my/models/sale.dart';
import 'package:sawitsense_my/providers/journal_provider.dart';
import 'package:sawitsense_my/providers/price_provider.dart';
import 'package:sawitsense_my/screens/journal_screen.dart';
import 'package:sawitsense_my/services/journal_codec.dart';
import 'package:sawitsense_my/services/price_service.dart';

/// MPOB's prices around a weekend: Thursday 22, Friday 23 and Monday 26
/// October 2026.
const _history = [
  FfbHistoryDay(date: '2026-10-22', prices: {'North': 47.82, 'Sabah': 43.06}),
  FfbHistoryDay(date: '2026-10-23', prices: {'North': 47.87}),
  FfbHistoryDay(date: '2026-10-26', prices: {'North': 47.92}),
];

class _FakePriceService extends PriceService {
  _FakePriceService(this.history);
  final List<FfbHistoryDay> history;

  @override
  Future<PriceSnapshot?> fetchLatest() async => null;

  @override
  Future<List<HistoricalPrice>> fetchHistory({int days = 30}) async => const [];

  @override
  Future<List<FfbHistoryDay>> fetchFfbHistory({int days = 30}) async => history;
}

/// A phone's storage and files, in memory.
class _MemoryDevice extends JournalDevice {
  _MemoryDevice({this.text, this.refuses = false});

  /// What is kept, as the browser's storage would hold it.
  String? text;

  /// True for a browser that won't keep anything.
  bool refuses;

  /// The file the reader will pick on Import.
  String? fileToPick;
  String? savedName;
  String? savedText;

  @override
  String? read() => text;

  @override
  bool write(String text) {
    if (refuses) return false;
    this.text = text;
    return true;
  }

  @override
  Future<bool> saveFile(String name, String text) async {
    savedName = name;
    savedText = text;
    return true;
  }

  @override
  Future<String?> pickFile() async => fileToPick;
}

const _saturdaySale =
    Sale(date: '2026-10-24', region: 'North', tonnes: 3, price: 770);
const _sabahSale = Sale(
    date: '2026-10-22', region: 'Sabah', tonnes: 2.5, price: 700, oer: 20);

List<Override> _overrides(_MemoryDevice device,
        {List<FfbHistoryDay> history = _history,
        AppLocale locale = AppLocale.en}) =>
    [
      priceServiceProvider.overrideWithValue(_FakePriceService(history)),
      journalDeviceProvider.overrideWithValue(device),
      todayProvider.overrideWithValue(() => DateTime(2026, 10, 23, 9, 30)),
      localeProvider.overrideWith((ref) => LocaleNotifier(initial: locale)),
    ];

Future<_MemoryDevice> _pump(WidgetTester tester,
    {List<Sale> stored = const [],
    AppLocale locale = AppLocale.en,
    _MemoryDevice? device}) async {
  final phone = device ??
      _MemoryDevice(text: stored.isEmpty ? null : encodeJournal(stored));
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: _overrides(phone, locale: locale),
    child: const MaterialApp(home: JournalScreen()),
  ));
  await tester.pumpAndSettle();
  return phone;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

JournalNotifier _notifier(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(JournalScreen)))
        .read(journalProvider.notifier);

void main() {
  group('One sale', () {
    const sale = Sale(
      date: '2026-10-23',
      region: 'North',
      tonnes: 5,
      price: 790,
      transport: 25,
      oer: 18.25,
      label: 'A',
      mpobPrice: 47.87,
      mpobDate: '2026-10-23',
    );

    test('what was kept and received', () {
      expect(sale.kept, 765);
      expect(sale.received, 3825);
    });

    test("the OER the price paid for, at MPOB's price for the day", () {
      expect(sale.paysForOer, closeTo(15.98, 0.005));
    });

    test("the gap to the mill-gate value at the receipt's OER", () {
      // RM 47.87 × 18.25% = RM 873.63.
      expect(sale.comparison!.fairPrice, 873.63);
      expect(sale.comparison!.gapRm, -108.63);
    });

    test('with no OER on the receipt there is no gap, only the OER paid for',
        () {
      const noOer = Sale(
          date: '2026-10-23',
          region: 'North',
          tonnes: 5,
          price: 790,
          mpobPrice: 47.87,
          mpobDate: '2026-10-23');
      expect(noOer.comparison, isNull);
      expect(noOer.paysForOer, isNotNull);
    });

    test("without MPOB's price nothing is compared", () {
      expect(_saturdaySale.paysForOer, isNull);
      expect(_saturdaySale.comparison, isNull);
    });
  });

  group("MPOB's price for the day of a sale", () {
    test('is that day\'s price for the region', () {
      final found = mpobPriceFor(_history, 'North', '2026-10-23');
      expect(found?.price, 47.87);
      expect(found?.date, '2026-10-23');
    });

    test('on a Saturday is the Friday\'s', () {
      final found = mpobPriceFor(_history, 'North', '2026-10-24');
      expect(found?.price, 47.87);
      expect(found?.date, '2026-10-23');
    });

    test('is not taken from more than a week before', () {
      expect(mpobPriceFor(_history, 'North', '2026-11-15'), isNull);
    });

    test('is not taken from a later day', () {
      expect(mpobPriceFor(_history, 'North', '2026-10-01'), isNull);
    });

    test('is none for a region MPOB gave no price', () {
      expect(mpobPriceFor(_history, 'Sarawak', '2026-10-23'), isNull);
    });

    test('a sale entered before MPOB publishes moves to its own day\'s price',
        () {
      const monday =
          Sale(date: '2026-10-26', region: 'North', tonnes: 4, price: 780);
      // On Monday morning the history ends on Friday.
      final morning = monday.withMpobPrice(_history.sublist(0, 2));
      expect(morning.mpobDate, '2026-10-23');
      expect(morning.mpobPrice, 47.87);
      // After noon MPOB's Monday price is there.
      final afternoon = morning.withMpobPrice(_history);
      expect(afternoon.mpobDate, '2026-10-26');
      expect(afternoon.mpobPrice, 47.92);
    });

    test('the price kept with a sale stays when the day leaves the history',
        () {
      final priced = _saturdaySale.withMpobPrice(_history);
      expect(identical(priced.withMpobPrice(const []), priced), isTrue);
      // A history that has lost Friday can't move the sale back to Thursday.
      final thursdayOnly = priced.withMpobPrice(_history.sublist(0, 1));
      expect(thursdayOnly.mpobDate, '2026-10-23');
    });
  });

  group('What can be read as a sale', () {
    Map<String, dynamic> row([Map<String, dynamic> changes = const {}]) => {
          'date': '2026-10-23',
          'region': 'North',
          'tonnes': 5.08,
          'price': 790,
          ...changes,
        };

    test('a plain row', () {
      final sale = Sale.tryParse(row())!;
      expect(sale.date, '2026-10-23');
      expect(sale.region, 'North');
      expect(sale.tonnes, 5.08);
      expect(sale.price, 790);
      expect(sale.transport, 0);
      expect(sale.oer, isNull);
      expect(sale.label, '');
    });

    test('a date as a spreadsheet rewrites it, day first', () {
      expect(normaliseDate('23/10/2026'), '2026-10-23');
      expect(normaliseDate('5-1-2026'), '2026-01-05');
      expect(normaliseDate('2026-1-5'), '2026-01-05');
    });

    test('not a date that isn\'t one', () {
      expect(normaliseDate('10/23/2026'), isNull);
      expect(normaliseDate('2026-02-30'), isNull);
      expect(normaliseDate('yesterday'), isNull);
      expect(Sale.tryParse(row({'date': '2026-02-30'})), isNull);
    });

    test('not an unknown region, though case doesn\'t matter', () {
      expect(Sale.tryParse(row({'region': 'east coast'}))!.region, 'East Coast');
      expect(Sale.tryParse(row({'region': 'Perak'})), isNull);
    });

    test('not a weight or a price of nothing', () {
      expect(Sale.tryParse(row({'tonnes': 0})), isNull);
      expect(Sale.tryParse(row({'price': -5})), isNull);
      expect(Sale.tryParse(row({'price': 'lots'})), isNull);
    });

    test('not transport that takes the whole price, or an OER out of range',
        () {
      expect(Sale.tryParse(row({'transport': 790})), isNull);
      expect(Sale.tryParse(row({'oer': 45})), isNull);
      expect(Sale.tryParse(row({'transport': 23, 'oer': 18.25}))!.kept, 767);
    });

    test('a dealer\'s name never gets in: only a letter A to F is kept', () {
      expect(Sale.tryParse(row({'label': 'b'}))!.label, 'B');
      expect(Sale.tryParse(row({'label': 'Kedai Sawit Ali'}))!.label, '');
      expect(Sale.tryParse(row({'label': 'G'}))!.label, '');
    });
  });

  group('The totals', () {
    test('add up by weight', () {
      final summary = JournalSummary.of([
        const Sale(
            date: '2026-10-23',
            region: 'North',
            tonnes: 5,
            price: 790,
            transport: 25,
            mpobPrice: 47.87,
            mpobDate: '2026-10-23'),
        _saturdaySale,
      ]);
      expect(summary.count, 2);
      expect(summary.tonnes, 8);
      // 5 × 765 + 3 × 770.
      expect(summary.received, 6135);
      expect(summary.averageKept, closeTo(766.88, 0.005));
      // Only the first sale has MPOB's price.
      expect(summary.averagePaysFor, closeTo(15.98, 0.005));
    });

    test('are empty for an empty journal', () {
      final summary = JournalSummary.of(const []);
      expect(summary.count, 0);
      expect(summary.averageKept, isNull);
      expect(summary.averagePaysFor, isNull);
    });

    test('the newest sale comes first', () {
      expect(newestFirst([_sabahSale, _saturdaySale]).first, _saturdaySale);
    });
  });

  group('On the phone', () {
    test('the journal is one JSON text, and reads back the same', () {
      final sales = [_sabahSale, _saturdaySale.withMpobPrice(_history)];
      final text = encodeJournal(sales);
      expect(text, startsWith('{"v":1,"sales":[{"date":"2026-10-22"'));

      final read = decodeJournal(text);
      expect(read.skipped, 0);
      expect(read.sales.length, 2);
      expect(read.sales[0].sameSaleAs(_sabahSale), isTrue);
      expect(read.sales[1].mpobPrice, 47.87);
      expect(read.sales[1].mpobDate, '2026-10-23');
    });

    test('nothing stored, or something damaged, is an empty journal', () {
      expect(decodeJournal(null).sales, isEmpty);
      expect(decodeJournal('').sales, isEmpty);
      expect(decodeJournal('{"v":1,"sales":').sales, isEmpty);
      expect(decodeJournal('[1,2,3]').sales, isEmpty);
    });

    test('a damaged sale is left out and the rest are kept', () {
      final read = decodeJournal('{"v":1,"sales":[{"date":"2026-10-23",'
          '"region":"North","tonnes":5,"price":790},{"date":"?"},7]}');
      expect(read.sales.length, 1);
      expect(read.skipped, 2);
    });
  });

  group('As a file', () {
    const full = Sale(
      date: '2026-10-23',
      region: 'North',
      tonnes: 5.08,
      price: 790,
      transport: 23,
      oer: 18.25,
      label: 'A',
      mpobPrice: 47.87,
      mpobDate: '2026-10-23',
    );
    const bare =
        Sale(date: '2026-10-24', region: 'Sabah', tonnes: 3, price: 740);

    test('the journal is CSV with a header row', () {
      expect(
          journalToCsv([full, bare]),
          'date,region,tonnes,price,transport,oer,label,mpob_price,mpob_date\r\n'
          '2026-10-23,North,5.08,790,23,18.25,A,47.87,2026-10-23\r\n'
          '2026-10-24,Sabah,3,740,,,,,\r\n');
    });

    test('what is exported can be imported again', () {
      final read = journalFromCsv(journalToCsv([full, bare]))!;
      expect(read.skipped, 0);
      expect(read.sales.length, 2);
      expect(read.sales[0].sameSaleAs(full), isTrue);
      expect(read.sales[0].mpobPrice, 47.87);
      expect(read.sales[1].sameSaleAs(bare), isTrue);
      expect(read.sales[1].mpobPrice, isNull);
    });

    test('a file a spreadsheet has saved again is still read', () {
      // A byte-order mark, semicolons, quoted cells, another column order, a
      // column of the reader's own, a day-first date and a decimal comma.
      final read = journalFromCsv('﻿Region;Date;Price;Tonnes;Notes\r\n'
          '"north";23/10/2026;790;5,08;sold early\r\n')!;
      expect(read.sales.length, 1);
      expect(read.sales.single.region, 'North');
      expect(read.sales.single.date, '2026-10-23');
      expect(read.sales.single.price, 790);
      expect(read.sales.single.tonnes, 5.08);
    });

    test('rows that make no sale are counted, not guessed at', () {
      final read = journalFromCsv('date,region,tonnes,price\n'
          '2026-10-23,North,5,790\n'
          '2026-10-23,North,,790\n'
          'total,,8,\n')!;
      expect(read.sales.length, 1);
      expect(read.skipped, 2);
    });

    test('a file that isn\'t a journal is refused', () {
      expect(journalFromCsv(''), isNull);
      expect(journalFromCsv('hello,world\n1,2\n'), isNull);
      expect(journalFromCsv('date,region,tonnes\n2026-10-23,North,5\n'), isNull);
    });
  });

  group('The journal', () {
    ProviderContainer container(_MemoryDevice device,
        {List<FfbHistoryDay> history = _history}) {
      final c = ProviderContainer(
          overrides: _overrides(device, history: history));
      addTearDown(c.dispose);
      return c;
    }

    test('opens with what the phone kept', () {
      final c = container(_MemoryDevice(text: encodeJournal([_sabahSale])));
      expect(c.read(journalProvider).sales.single.sameSaleAs(_sabahSale),
          isTrue);
      expect(c.read(journalProvider).kept, isTrue);
    });

    test('keeps each change on the phone', () {
      final device = _MemoryDevice();
      final c = container(device);
      final journal = c.read(journalProvider.notifier);

      journal.add(_sabahSale);
      expect(decodeJournal(device.text).sales.length, 1);

      journal.add(_saturdaySale);
      expect(decodeJournal(device.text).sales.length, 2);

      journal.remove(c.read(journalProvider).sales.first);
      expect(decodeJournal(device.text).sales.single.region, 'North');

      journal.clear();
      expect(decodeJournal(device.text).sales, isEmpty);
    });

    test('says so when the browser won\'t keep it', () {
      final c = container(_MemoryDevice(refuses: true));
      c.read(journalProvider.notifier).add(_sabahSale);
      expect(c.read(journalProvider).kept, isFalse);
      // The sale is still there while the page is open.
      expect(c.read(journalProvider).sales.length, 1);
    });

    test("sets its sales against MPOB's prices once they load, and keeps them",
        () async {
      final device = _MemoryDevice(text: encodeJournal([_saturdaySale]));
      final c = container(device);
      expect(c.read(journalProvider).sales.single.mpobPrice, isNull);

      await c.read(journalPricesProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(c.read(journalProvider).sales.single.mpobPrice, 47.87);
      expect(decodeJournal(device.text).sales.single.mpobDate, '2026-10-23');
    });

    test('a sale added after the prices loaded is priced at once', () async {
      final c = container(_MemoryDevice());
      c.read(journalProvider);
      await c.read(journalPricesProvider.future);
      await Future<void>.delayed(Duration.zero);

      c.read(journalProvider.notifier).add(_sabahSale);
      expect(c.read(journalProvider).sales.single.mpobPrice, 43.06);
    });

    test('an import adds only the sales that aren\'t there yet', () {
      final c = container(_MemoryDevice(text: encodeJournal([_sabahSale])));
      final added = c
          .read(journalProvider.notifier)
          .addNew([_sabahSale, _saturdaySale, _saturdaySale]);
      expect(added, 1);
      expect(c.read(journalProvider).sales.length, 2);
    });
  });

  group('The screen', () {
    testWidgets('an empty journal says where it is kept', (tester) async {
      await _pump(tester);

      expect(find.text('My Sales Journal'), findsOneWidget);
      expect(find.textContaining('kept on this phone only'), findsOneWidget);
      expect(find.textContaining('No sales yet'), findsOneWidget);
      expect(find.text('All sales'), findsNothing);
      expect(find.text('Delete all'), findsNothing);
    });

    testWidgets('adding a sale shows it against MPOB\'s price and keeps it',
        (tester) async {
      final device = await _pump(tester);

      await _tap(tester, find.text('Add a sale'));
      await _tap(tester, find.byType(DropdownButtonFormField<String>));
      await _tap(tester, find.text('North').last);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '5');
      await tester.enterText(fields.at(1), '790');
      await tester.enterText(fields.at(2), '25');
      await tester.enterText(fields.at(3), '18.25');
      await _tap(tester, find.widgetWithText(ChoiceChip, 'A'));
      await _tap(tester, find.text('Save'));

      // The sale, dated today.
      expect(find.text('23 Oct 2026 · North · Dealer A'), findsOneWidget);
      expect(find.text('5 t × RM 765 = RM 3,825.00'), findsOneWidget);
      expect(find.text('RM 790 less RM 25 transport = RM 765 a tonne'),
          findsOneWidget);
      expect(find.text('Pays for 16.0% OER (MPOB 47.87 on 23 Oct)'),
          findsOneWidget);
      expect(
          find.text('RM 108.63 (12.4%) below the mill-gate value at 18.25% OER'),
          findsOneWidget);
      // The totals.
      expect(find.text('Received: RM 3,825.00'), findsOneWidget);
      expect(find.text('Sales: 1 · 5 tonnes'), findsOneWidget);
      expect(find.text('Average kept: RM 765.00 a tonne'), findsOneWidget);
      expect(find.text('Your prices paid for 16.0% OER on average'),
          findsOneWidget);
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(find.text('Sales: 1 · 5 t · RM 3,825.00'), findsOneWidget);

      // And it is on the phone.
      final kept = decodeJournal(device.text).sales.single;
      expect(kept.date, '2026-10-23');
      expect(kept.label, 'A');
      expect(kept.mpobPrice, 47.87);
    });

    testWidgets('a sale needs a region, a weight and a price', (tester) async {
      final device = await _pump(tester);

      await _tap(tester, find.text('Add a sale'));
      await _tap(tester, find.text('Save'));

      expect(find.text('Required'), findsNWidgets(3));
      expect(device.text, isNull);
    });

    testWidgets('kept sales open newest first, a Saturday against Friday',
        (tester) async {
      final device =
          await _pump(tester, stored: [_sabahSale, _saturdaySale]);

      expect(find.text('24 Oct 2026 · North'), findsOneWidget);
      expect(find.text('Pays for 16.1% OER (MPOB 47.87 on 23 Oct)'),
          findsOneWidget);
      expect(find.text('22 Oct 2026 · Sabah'), findsOneWidget);
      expect(find.text('Pays for 16.3% OER (MPOB 43.06 on 22 Oct)'),
          findsOneWidget);
      expect(find.text('RM 161.2 (18.7%) below the mill-gate value at 20% OER'),
          findsOneWidget);
      expect(find.text('Received: RM 4,060.00'), findsOneWidget);
      expect(find.text('Sales: 2 · 5.5 tonnes'), findsOneWidget);

      final north = tester.getTopLeft(find.text('24 Oct 2026 · North'));
      final sabah = tester.getTopLeft(find.text('22 Oct 2026 · Sabah'));
      expect(north.dy, lessThan(sabah.dy));
      // MPOB's prices are now kept with the sales.
      expect(device.text, contains('"mpob_price":47.87'));
    });

    testWidgets("a sale older than the app's history is shown uncompared",
        (tester) async {
      await _pump(tester, stored: const [
        Sale(date: '2026-08-03', region: 'North', tonnes: 4, price: 800),
      ]);

      expect(find.text('4 t × RM 800 = RM 3,200.00'), findsOneWidget);
      expect(find.textContaining('cannot be compared'), findsOneWidget);
      expect(find.textContaining('paid for'), findsNothing);
    });

    testWidgets('one sale is deleted after a yes', (tester) async {
      final device =
          await _pump(tester, stored: [_sabahSale, _saturdaySale]);

      await _tap(tester, find.byTooltip('Delete').first);
      expect(find.text('Delete this sale?'), findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Delete'));

      expect(find.text('24 Oct 2026 · North'), findsNothing);
      expect(find.text('22 Oct 2026 · Sabah'), findsOneWidget);
      expect(decodeJournal(device.text).sales.single.region, 'Sabah');
    });

    testWidgets('a no leaves the sale where it is', (tester) async {
      final device =
          await _pump(tester, stored: [_sabahSale, _saturdaySale]);

      await _tap(tester, find.byTooltip('Delete').first);
      await _tap(tester, find.widgetWithText(TextButton, 'Cancel'));

      expect(decodeJournal(device.text).sales.length, 2);
    });

    testWidgets('everything is deleted only after a yes', (tester) async {
      final device =
          await _pump(tester, stored: [_sabahSale, _saturdaySale]);

      await _tap(tester, find.text('Delete all'));
      expect(find.textContaining('Delete every sale (2) from this phone?'),
          findsOneWidget);
      await _tap(tester, find.widgetWithText(TextButton, 'Delete all').last);

      expect(find.textContaining('No sales yet'), findsOneWidget);
      expect(decodeJournal(device.text).sales, isEmpty);
    });

    testWidgets('Export saves the journal as a dated CSV file, oldest first',
        (tester) async {
      final device =
          await _pump(tester, stored: [_saturdaySale, _sabahSale]);

      await _tap(tester, find.text('Export'));

      expect(device.savedName, 'sawitsense-sales-2026-10-23.csv');
      expect(
          device.savedText,
          'date,region,tonnes,price,transport,oer,label,mpob_price,mpob_date\r\n'
          '2026-10-22,Sabah,2.5,700,,20,,43.06,2026-10-22\r\n'
          '2026-10-24,North,3,770,,,,47.87,2026-10-23\r\n');
      expect(
          find.text('Saved as sawitsense-sales-2026-10-23.csv (sales: 2).'),
          findsOneWidget);
    });

    testWidgets('Import adds the new sales and says what it left out',
        (tester) async {
      final device = await _pump(tester, stored: [_sabahSale]);
      device.fileToPick = 'date,region,tonnes,price,oer\n'
          '2026-10-22,Sabah,2.5,700,20\n' // already here
          '2026-10-24,North,3,770,\n' // new
          'total,,5.5,,\n'; // not a sale

      await _tap(tester, find.text('Import'));

      expect(
          find.text(
              'Sales added: 1. Left out: 2 (already here, or not readable).'),
          findsOneWidget);
      expect(find.text('24 Oct 2026 · North'), findsOneWidget);
      expect(decodeJournal(device.text).sales.length, 2);
    });

    testWidgets('Import refuses a file that isn\'t a journal', (tester) async {
      final device = await _pump(tester, stored: [_sabahSale]);
      device.fileToPick = 'hello,world\n1,2\n';

      await _tap(tester, find.text('Import'));

      expect(find.text('That file could not be read as a SawitSense journal.'),
          findsOneWidget);
      expect(decodeJournal(device.text).sales.length, 1);
    });

    testWidgets('a browser that won\'t keep the journal is named as one',
        (tester) async {
      await _pump(tester, device: _MemoryDevice(refuses: true));
      expect(find.textContaining('is not keeping the journal'), findsNothing);

      _notifier(tester).add(_sabahSale);
      await tester.pumpAndSettle();

      expect(find.textContaining('is not keeping the journal'), findsOneWidget);
    });

    testWidgets('in BM', (tester) async {
      await _pump(tester, stored: [_sabahSale], locale: AppLocale.ms);

      expect(find.text('Jurnal Jualan Saya'), findsOneWidget);
      expect(find.text('22 Okt 2026 · Sabah'), findsOneWidget);
      expect(find.text('2.5 tan × RM 700 = RM 1,750.00'), findsOneWidget);
      expect(find.text('Bersamaan 16.3% OER (MPOB 43.06 pada 22 Okt)'),
          findsOneWidget);
      expect(
          find.text('RM 161.2 (18.7%) di bawah nilai pintu kilang pada 20% OER'),
          findsOneWidget);
    });

    testWidgets('in 中文, with no English left on the screen or in the form',
        (tester) async {
      await _pump(tester, stored: [_sabahSale], locale: AppLocale.zh);

      expect(find.text('我的销售记录'), findsOneWidget);
      expect(find.text('2026年10月22日 · 沙巴'), findsOneWidget);
      expect(find.text('2.5 公吨 × RM 700 = RM 1,750.00'), findsOneWidget);
      expect(find.text('相当于 16.3% 出油率（MPOB 10月22日 价格 43.06）'), findsOneWidget);
      expect(find.text('按 20% 出油率，比厂门价值低 RM 161.2（18.7%）'), findsOneWidget);

      await _tap(tester, find.text('添加一笔销售'));
      expect(find.text('销售日期'), findsOneWidget);

      final zh = stringsFor(AppLocale.zh);
      final english = {
        for (final e in enStrings.entries)
          if (zh[e.key] != e.value) e.value,
      };
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      expect(shown.where(enStrings.containsKey), isEmpty);
      expect(shown.where(english.contains), isEmpty);
    });
  });

  group('Money', () {
    test('is written with thousands and cents', () {
      expect(journalMoney(3896.2), '3,896.20');
      expect(journalMoney(765), '765.00');
      expect(journalMoney(1234567.891), '1,234,567.89');
      expect(journalMoney(0), '0.00');
    });
  });
}
