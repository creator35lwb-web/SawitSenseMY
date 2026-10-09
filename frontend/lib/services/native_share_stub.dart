// Outside the web build (e.g. in tests) there is no share sheet, so the app
// shows its own Share panel. The web build uses native_share_web.dart.
//
// Author: SS (Claude Code), Oct 2026

/// True on a touch screen whose browser has a share sheet.
bool canNativeShare() => false;

/// Opens the share sheet (not possible here).
Future<void> nativeShare({
  required String title,
  required String text,
  required String url,
}) async {}
