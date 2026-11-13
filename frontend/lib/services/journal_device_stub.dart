// Outside the web build (e.g. in tests) there is no browser storage and no
// file to save or pick, so the journal lasts only while the app is open.
// The web build uses journal_device_web.dart.
//
// Author: SS (Claude Code), Nov 2026

/// The journal's JSON text as last kept here, if any.
String? readJournalText() => null;

/// Keeps [text] on this phone (not possible here).
bool writeJournalText(String text) => false;

/// Asks the browser to save [text] as a file called [name] (not possible
/// here).
Future<bool> saveJournalFile(String name, String text) async => false;

/// Lets the reader pick a CSV file and returns its text (not possible here).
Future<String?> pickJournalFile() async => null;
