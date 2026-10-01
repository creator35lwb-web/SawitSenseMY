// Tells Flutter which languages the app speaks, and keeps Flutter's own
// built-in labels (e.g. a text field's Copy/Paste menu, a menu button's
// tooltip) working in each of them.
//
// The app's words are translated in app_en/app_ms/app_zh.dart. Flutter's
// built-in labels stay in English: translating them needs the
// flutter_localizations package, which would change pubspec.lock (the D9
// constraint). Telling Flutter the reader's language still matters, because
// Flutter sets the page's `lang` from it, so screen readers use the right
// voice.
//
// Author: SS (Claude Code), Oct 2026

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'l10n_provider.dart';

/// The app's languages as Flutter locales, for MaterialApp.supportedLocales.
final List<Locale> appSupportedLocales = [
  for (final locale in AppLocale.values) locale.flutterLocale,
];

/// Flutter's built-in labels, in English, for every language the app speaks.
/// Without these, a widget that needs them would find none in BM or Chinese.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  _MaterialLabels(),
  _CupertinoLabels(),
];

class _MaterialLabels extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialLabels();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(_MaterialLabels old) => false;
}

class _CupertinoLabels extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoLabels();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(_CupertinoLabels old) => false;
}
