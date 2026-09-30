// Honest "prices unavailable" state with a retry button.
//
// Shown instead of demo data when prices can't be loaded, so a smallholder
// never compares a dealer's quote against made-up numbers.
//
// Author: SS (Claude Code), Sep 2026

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

class UnavailableNotice extends ConsumerWidget {
  final VoidCallback onRetry;

  const UnavailableNotice({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              tr('prices_unavailable'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}
