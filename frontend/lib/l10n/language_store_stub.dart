// Outside the web build (e.g. in tests) there is no browser storage or page,
// so no language choice is remembered and no page language is set. The web
// build uses language_store_web.dart.
//
// Author: SS (Claude Code), Sep 2026

/// The language code the reader last chose here, if any.
String? readSavedLanguage() => null;

/// Keeps [code] for the next visit (not possible here).
void saveLanguage(String code) {}

/// Sets the page's language tag (there is no page here).
void setPageLanguage(String tag) {}
