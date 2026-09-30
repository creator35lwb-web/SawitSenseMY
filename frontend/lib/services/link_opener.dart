// Opens official sources and project documents in the browser.
//
// A provider, so widget tests can check which link a tap opens without the
// url_launcher plugin.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LinkOpener = Future<bool> Function(Uri uri);

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
