// The phone's own share sheet (the Web Share API), used on touch screens:
// it offers whatever apps the reader has, such as WhatsApp.
//
// Web build only; tests and other platforms use native_share_stub.dart.
//
// Author: SS (Claude Code), Oct 2026
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// True on a touch screen whose browser has a share sheet.
bool canNativeShare() {
  try {
    final navigator = globalContext.getProperty<JSObject?>('navigator'.toJS);
    if (navigator == null || !navigator.has('share')) return false;
    final query = globalContext.callMethod<JSObject?>(
        'matchMedia'.toJS, '(pointer: coarse)'.toJS);
    return query?.getProperty<JSBoolean?>('matches'.toJS)?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

/// Opens the share sheet. Closing it without sharing is not an error.
Future<void> nativeShare({
  required String title,
  required String text,
  required String url,
}) async {
  try {
    final navigator = globalContext.getProperty<JSObject>('navigator'.toJS);
    final data = {'title': title, 'text': text, 'url': url}.jsify();
    await navigator
        .callMethod<JSPromise<JSAny?>>('share'.toJS, data)
        .toDart;
  } catch (_) {
    // Dismissed by the reader, or blocked by the browser: nothing to do.
  }
}
