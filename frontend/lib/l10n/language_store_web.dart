// The browser side of the language setting. It remembers the reader's language
// in this browser (localStorage), so the app opens in it next time. Only "en",
// "ms" or "zh" is stored: no personal data, and it never leaves the phone. It
// also tells the page which language is showing, for screen readers.
//
// Web build only; tests and other platforms use language_store_stub.dart.
//
// Author: SS (Claude Code), Sep 2026
// Patch: SS (Claude Code), Oct 2026 — setPageLanguage().
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

/// Sets the page's `lang` to [tag] (e.g. "zh-Hans"), so screen readers read
/// it in the right voice.
void setPageLanguage(String tag) {
  try {
    globalContext
        .getProperty<JSObject?>('document'.toJS)
        ?.getProperty<JSObject?>('documentElement'.toJS)
        ?.setProperty('lang'.toJS, tag.toJS);
  } catch (_) {
    // Not critical: the page keeps its previous language tag.
  }
}
