// Where the sales journal lives on the reader's phone, and how it leaves and
// returns as a file (D29). Web build only; tests and other platforms use
// journal_device_stub.dart.
//
// - Kept: one JSON text in this browser's localStorage, under
//   "sawitsense.journal". It never leaves the phone by itself: the app has no
//   server to send it to, and nothing here makes a network request.
// - Exported: the browser saves a CSV file wherever the reader chooses.
// - Imported: the reader picks a CSV file; it is read on the phone.
//
// Author: SS (Claude Code), Nov 2026
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _key = 'sawitsense.journal';

/// The browser's localStorage, or null where it is blocked (some privacy
/// settings throw on access).
JSObject? _storage() {
  try {
    return globalContext.getProperty<JSObject?>('localStorage'.toJS);
  } catch (_) {
    return null;
  }
}

/// The journal's JSON text as last kept here, if any.
String? readJournalText() {
  try {
    return _storage()
        ?.callMethod<JSString?>('getItem'.toJS, _key.toJS)
        ?.toDart;
  } catch (_) {
    return null;
  }
}

/// Keeps [text] on this phone. False when the browser won't: storage is
/// blocked or full, or the page is in a private window that discards it.
bool writeJournalText(String text) {
  try {
    final storage = _storage();
    if (storage == null) return false;
    storage.callMethod<JSAny?>('setItem'.toJS, _key.toJS, text.toJS);
    return storage
            .callMethod<JSString?>('getItem'.toJS, _key.toJS)
            ?.toDart ==
        text;
  } catch (_) {
    return false;
  }
}

/// Asks the browser to save [text] as a file called [name]. False when it
/// can't be done here.
Future<bool> saveJournalFile(String name, String text) async {
  try {
    final blobType = globalContext.getProperty<JSFunction>('Blob'.toJS);
    final blob = blobType.callAsConstructor<JSObject>(
        [text].jsify(), {'type': 'text/csv;charset=utf-8'}.jsify());
    final urls = globalContext.getProperty<JSObject>('URL'.toJS);
    final url = urls.callMethod<JSString>('createObjectURL'.toJS, blob);

    final document = globalContext.getProperty<JSObject>('document'.toJS);
    final body = document.getProperty<JSObject>('body'.toJS);
    final link = document.callMethod<JSObject>('createElement'.toJS, 'a'.toJS);
    link.setProperty('href'.toJS, url);
    link.setProperty('download'.toJS, name.toJS);
    link.getProperty<JSObject>('style'.toJS)
        .setProperty('display'.toJS, 'none'.toJS);
    body.callMethod<JSAny?>('appendChild'.toJS, link);
    link.callMethod<JSAny?>('click'.toJS);
    body.callMethod<JSAny?>('removeChild'.toJS, link);
    // Give the browser a moment to start the download before the link to the
    // text is withdrawn.
    Timer(const Duration(seconds: 30),
        () => urls.callMethod<JSAny?>('revokeObjectURL'.toJS, url));
    return true;
  } catch (_) {
    return false;
  }
}

/// Lets the reader pick a CSV file and returns its text; null when they
/// pick none or it can't be read. The file is read on the phone.
Future<String?> pickJournalFile() {
  final picked = Completer<String?>();
  void finish(String? text) {
    if (!picked.isCompleted) picked.complete(text);
  }

  try {
    final document = globalContext.getProperty<JSObject>('document'.toJS);
    final body = document.getProperty<JSObject>('body'.toJS);
    final input =
        document.callMethod<JSObject>('createElement'.toJS, 'input'.toJS);
    input.setProperty('type'.toJS, 'file'.toJS);
    input.setProperty('accept'.toJS, '.csv,text/csv,text/plain'.toJS);
    input.getProperty<JSObject>('style'.toJS)
        .setProperty('display'.toJS, 'none'.toJS);

    void remove() {
      try {
        body.callMethod<JSAny?>('removeChild'.toJS, input);
      } catch (_) {
        // Already gone.
      }
    }

    void onChange(JSAny? _) {
      () async {
        try {
          final files = input.getProperty<JSObject?>('files'.toJS);
          final file = files?.callMethod<JSObject?>('item'.toJS, 0.toJS);
          if (file == null) {
            finish(null);
            return;
          }
          final text = await file
              .callMethod<JSPromise<JSString>>('text'.toJS)
              .toDart;
          finish(text.toDart);
        } catch (_) {
          finish(null);
        } finally {
          remove();
        }
      }();
    }

    void onCancel(JSAny? _) {
      finish(null);
      remove();
    }

    input.callMethod<JSAny?>(
        'addEventListener'.toJS, 'change'.toJS, onChange.toJS);
    input.callMethod<JSAny?>(
        'addEventListener'.toJS, 'cancel'.toJS, onCancel.toJS);
    body.callMethod<JSAny?>('appendChild'.toJS, input);
    input.callMethod<JSAny?>('click'.toJS);
  } catch (_) {
    finish(null);
  }
  return picked.future;
}
