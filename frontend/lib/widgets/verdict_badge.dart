/// Verdict badge: GREEN / AMBER / RED.
import 'package:flutter/material.dart';

class VerdictBadge extends StatelessWidget {
  final String verdict;

  const VerdictBadge({super.key, required this.verdict});

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
  Widget build(BuildContext context) {
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
            verdict,
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
