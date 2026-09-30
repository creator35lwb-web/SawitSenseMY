// A tappable source label that opens the official page, e.g.
// "MPOC Daily Palm Oil Prices ↗".
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/link_opener.dart';

class SourceLink extends ConsumerWidget {
  final String label;
  final String url;

  /// Defaults to the theme's primary colour.
  final Color? color;
  final double fontSize;

  const SourceLink({
    super.key,
    required this.label,
    required this.url,
    this.color,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkColor = color ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => ref.read(linkOpenerProvider)(Uri.parse(url)),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: linkColor,
                    fontSize: fontSize,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.open_in_new, size: fontSize + 2, color: linkColor),
            ],
          ),
        ),
      ),
    );
  }
}
