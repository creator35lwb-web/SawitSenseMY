// The sales journal's state (D29): the reader's sales, kept on their phone.
//
// Author: SS (Claude Code), Nov 2026
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_data.dart';
import '../models/sale.dart';
import '../services/journal_codec.dart';
import '../services/journal_device_stub.dart'
    if (dart.library.js_interop) '../services/journal_device_web.dart'
    as device;
import 'price_provider.dart';

/// Where the journal is kept, and how it leaves and returns as a file. The
/// app uses the browser; tests put something in its place.
class JournalDevice {
  const JournalDevice();

  /// The journal's JSON text as last kept, if any.
  String? read() => device.readJournalText();

  /// Keeps [text]; false when the browser won't.
  bool write(String text) => device.writeJournalText(text);

  /// Saves [text] as a file called [name]; false when it can't be done.
  Future<bool> saveFile(String name, String text) =>
      device.saveJournalFile(name, text);

  /// The text of a file the reader picks; null when they pick none.
  Future<String?> pickFile() => device.pickJournalFile();
}

final journalDeviceProvider =
    Provider<JournalDevice>((ref) => const JournalDevice());

/// Today, for a new sale's date and an exported file's name. Tests fix it.
final todayProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// MPOB's daily prices for as far back as the app's history goes, to set
/// each sale against the price of its day. Empty when it can't be loaded.
final journalPricesProvider = FutureProvider<List<FfbHistoryDay>>((ref) async {
  final service = ref.read(priceServiceProvider);
  return service.fetchFfbHistory(days: 400);
});

class JournalState {
  /// The reader's sales, in the order they were entered.
  final List<Sale> sales;

  /// False when the browser refused the last save, so the sales will be gone
  /// when the page closes unless the reader exports them.
  final bool kept;

  const JournalState({this.sales = const [], this.kept = true});
}

class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier(this._device)
      : super(JournalState(sales: decodeJournal(_device.read()).sales));

  final JournalDevice _device;

  /// MPOB's daily prices as last loaded, for the sales added from now on.
  List<FfbHistoryDay> _history = const [];

  void _set(List<Sale> sales) {
    state = JournalState(
      sales: List.unmodifiable(sales),
      kept: _device.write(encodeJournal(sales)),
    );
  }

  /// Adds [sale] to the journal.
  void add(Sale sale) =>
      _set([...state.sales, sale.withMpobPrice(_history)]);

  /// Adds those of [sales] that aren't in the journal already, and returns
  /// how many that was.
  int addNew(Iterable<Sale> sales) {
    final all = [...state.sales];
    var added = 0;
    for (final sale in sales) {
      if (all.any(sale.sameSaleAs)) continue;
      all.add(sale.withMpobPrice(_history));
      added++;
    }
    if (added > 0) _set(all);
    return added;
  }

  /// Takes [sale] out of the journal.
  void remove(Sale sale) =>
      _set([for (final s in state.sales) if (!identical(s, sale)) s]);

  /// Empties the journal.
  void clear() => _set(const []);

  /// Sets each sale against MPOB's price for its day, from [history], and
  /// keeps [history] for the sales added later. Nothing is saved when no
  /// sale changes.
  void fillPrices(List<FfbHistoryDay> history) {
    if (history.isEmpty) return;
    _history = history;
    final before = state.sales;
    final filled = [for (final sale in before) sale.withMpobPrice(history)];
    for (var i = 0; i < filled.length; i++) {
      if (!identical(filled[i], before[i])) {
        _set(filled);
        return;
      }
    }
  }
}

final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final notifier = JournalNotifier(ref.watch(journalDeviceProvider));
  // MPOB's prices arrive after the journal opens, and again whenever they
  // are reloaded.
  ref.listen<AsyncValue<List<FfbHistoryDay>>>(journalPricesProvider,
      (_, next) {
    final history = next.asData?.value;
    if (history != null) notifier.fillPrices(history);
  }, fireImmediately: true);
  return notifier;
});
