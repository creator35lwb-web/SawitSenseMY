/// Feedback button with 3 preset options.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';

class FeedbackButton extends ConsumerWidget {
  const FeedbackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);

    return OutlinedButton.icon(
      onPressed: () => _showFeedbackDialog(context, ref),
      icon: const Icon(Icons.feedback_outlined, size: 18),
      label: Text(tr('feedback_title')),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green.shade700,
        side: BorderSide(color: Colors.green.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('feedback_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FeedbackOption(
              icon: Icons.thumb_up_outlined,
              label: tr('feedback_helpful'),
              color: Colors.green,
              onTap: () => _submitFeedback(ctx, tr, 'helpful'),
            ),
            const SizedBox(height: 8),
            _FeedbackOption(
              icon: Icons.help_outline,
              label: tr('feedback_confusing'),
              color: Colors.orange,
              onTap: () => _submitFeedback(ctx, tr, 'confusing'),
            ),
            const SizedBox(height: 8),
            _FeedbackOption(
              icon: Icons.report_outlined,
              label: tr('feedback_wrong'),
              color: Colors.red,
              onTap: () => _submitFeedback(ctx, tr, 'wrong_price'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _submitFeedback(BuildContext ctx, String Function(String) tr, String type) {
    Navigator.of(ctx).pop();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(tr('feedback_thanks')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
    // Future: send to Firestore analytics
    debugPrint('[SawitSense] Feedback submitted: $type');
  }
}

class _FeedbackOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _FeedbackOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color.shade700),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
    );
  }
}
