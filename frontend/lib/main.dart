// SawitSense MY — Entry Point
//
// Sawit Kita, Harga Kita.
// Open-Source CPO Price Tracker & OER Signal for Malaysian Smallholders.
//
// Author: QQ (Qoder CSO)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SawitSenseApp(),
    ),
  );
}
