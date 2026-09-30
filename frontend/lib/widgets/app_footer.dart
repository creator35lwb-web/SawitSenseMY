// App footer with version, links (open data, GitHub, social), and disclaimer.
//
// Patch: SS (Claude Code), Sep 2026 — "Open data" link; links open through
// linkOpenerProvider; chips wrap on narrow screens.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import '../services/link_opener.dart';

const String appVersion = '0.3.5';

class AppFooter extends ConsumerWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    void open(String url) => ref.read(linkOpenerProvider)(Uri.parse(url));

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
          // Links: open data first, then code and social
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _SocialChip(
                icon: Icons.table_chart_outlined,
                label: tr('footer_open_data'),
                onTap: () => open(openDataUrl),
              ),
              _SocialChip(
                icon: Icons.code,
                label: 'GitHub',
                onTap: () =>
                    open('https://github.com/creator35lwb-web/SawitSenseMY'),
              ),
              _SocialChip(
                icon: Icons.alternate_email,
                label: 'X',
                onTap: () => open('https://x.com/creator35lwb'),
              ),
              _SocialChip(
                icon: Icons.person_outline,
                label: 'LinkedIn',
                onTap: () => open('https://linkedin.com/in/altonlee92'),
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
