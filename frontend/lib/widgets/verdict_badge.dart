// Verdict badge: GREEN / AMBER / RED.
//
// Patch: SS (Claude Code), Sep 2026 — the colour is named in the chosen
// language (e.g. HIJAU, 绿灯) instead of always in English.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

class VerdictBadge extends ConsumerWidget {
  final String verdict;

  const VerdictBadge({super.key, required this.verdict});

  String _label(String Function(String) tr) => switch (verdict) {
        'GREEN' => tr('verdict_badge_green'),
        'AMBER' => tr('verdict_badge_amber'),
        'RED' => tr('verdict_badge_red'),
        _ => verdict,
      };

  Color _bgColor() {
    switch (verdict) {
      case 'GREEN':
        return Colors.green.shade100;
      case 'AMBER':
        return Colors.amber.shade100;
      case 'RED':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _fgColor() {
    switch (verdict) {
      case 'GREEN':
        return Colors.green.shade800;
      case 'AMBER':
        return Colors.amber.shade900;
      case 'RED':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  IconData _icon() {
    switch (verdict) {
      case 'GREEN':
        return Icons.check_circle;
      case 'AMBER':
        return Icons.warning_amber_rounded;
      case 'RED':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), color: _fgColor(), size: 22),
          const SizedBox(width: 8),
          Text(
            _label(tr),
            style: TextStyle(
              color: _fgColor(),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
