// Remembers the reader's language in this browser (localStorage), so the app
// opens in it next time. Only "en", "ms" or "zh" is stored: no personal data,
// and it never leaves the phone. (The page's `lang` is set by Flutter from the
// app's locale; see builtin_labels.dart.)
//
// Web build only; tests and other platforms use language_store_stub.dart.
//
// Author: SS (Claude Code), Sep 2026
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _key = 'sawitsense.language';

/// The browser's localStorage, or null where it is blocked (some privacy
/// settings throw on access).
JSObject? _storage() {
  try {
    return globalContext.getProperty<JSObject?>('localStorage'.toJS);
  } catch (_) {
    return null;
  }
}

/// The language code the reader last chose here, if any.
String? readSavedLanguage() {
  try {
    return _storage()
        ?.callMethod<JSString?>('getItem'.toJS, _key.toJS)
        ?.toDart;
  } catch (_) {
    return null;
  }
}

/// Keeps [code] for the next visit.
void saveLanguage(String code) {
  try {
    _storage()?.callMethod<JSAny?>('setItem'.toJS, _key.toJS, code.toJS);
  } catch (_) {
    // Not remembered; the next visit follows the phone's language again.
  }
}
