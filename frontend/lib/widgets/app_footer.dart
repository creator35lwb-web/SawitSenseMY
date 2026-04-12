// App footer with version, social links, and disclaimer.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n_provider.dart';

const String appVersion = '0.2.1';

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Social links row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialChip(
                icon: Icons.code,
                label: 'GitHub',
                onTap: () => _launch(
                    'https://github.com/creator35lwb-web/SawitSenseMY'),
              ),
              const SizedBox(width: 12),
              _SocialChip(
                icon: Icons.alternate_email,
                label: 'X',
                onTap: () => _launch('https://x.com/creator35lwb'),
              ),
              const SizedBox(width: 12),
              _SocialChip(
                icon: Icons.person_outline,
                label: 'LinkedIn',
                onTap: () =>
                    _launch('https://linkedin.com/in/altonlee92'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Disclaimer
          Text(
            tr('footer_disclaimer'),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Version + open source badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_open, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${tr('footer_open_source')}  •  v$appVersion',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      side: BorderSide(color: Colors.grey.shade300),
      backgroundColor: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
