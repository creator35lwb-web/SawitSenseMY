// Share button: lets readers pass SawitSense on, so more smallholders find it
// (and send feedback).
//
// On a phone it opens the phone's own share sheet (WhatsApp and whatever else
// the reader has). Elsewhere it shows a small panel: copy the link, or share
// to WhatsApp, Facebook, X, LinkedIn or email. The link is the plain site
// address; nothing about the reader is added to it.
//
// Author: SS (Claude Code), Oct 2026
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/links.dart';
import '../l10n/l10n_provider.dart';
import '../services/link_opener.dart';
import '../services/share_links.dart';
import '../services/native_share_stub.dart'
    if (dart.library.js_interop) '../services/native_share_web.dart';

/// The phone's share sheet. Tests replace it.
class NativeShare {
  const NativeShare();

  bool get available => canNativeShare();

  Future<void> share({
    required String title,
    required String text,
    required String url,
  }) =>
      nativeShare(title: title, text: text, url: url);
}

final nativeShareProvider = Provider<NativeShare>((ref) => const NativeShare());

class ShareButton extends ConsumerWidget {
  const ShareButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);

    return OutlinedButton.icon(
      onPressed: () => _share(context, ref),
      icon: const Icon(Icons.share_outlined, size: 18),
      label: Text(tr('share_button')),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green.shade700,
        side: BorderSide(color: Colors.green.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _share(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    final native = ref.read(nativeShareProvider);
    if (native.available) {
      native.share(
          title: tr('app_title'), text: tr('share_pitch'), url: siteUrl);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SharePanel(),
    );
  }
}

class SharePanel extends ConsumerWidget {
  const SharePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    void open(ShareTarget target) {
      Navigator.of(context).pop();
      ref.read(linkOpenerProvider)(shareLink(
        target,
        text: tr('share_pitch'),
        url: siteUrl,
        emailSubject: tr('share_email_subject'),
      ));
    }

    Future<void> copy() async {
      final messenger = ScaffoldMessenger.of(context);
      await Clipboard.setData(const ClipboardData(text: siteUrl));
      messenger.showSnackBar(SnackBar(
        content: Text(tr('share_link_copied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }

    final targets = <(ShareTarget, IconData, String)>[
      (ShareTarget.whatsapp, Icons.chat_outlined, 'WhatsApp'),
      (ShareTarget.facebook, Icons.facebook, 'Facebook'),
      (ShareTarget.x, Icons.alternate_email, 'X'),
      (ShareTarget.linkedin, Icons.work_outline, 'LinkedIn'),
      (ShareTarget.email, Icons.email_outlined, tr('share_email')),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('share_title'),
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(tr('share_pitch')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    siteUrl,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: copy,
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(tr('share_copy_link')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (target, icon, label) in targets)
                  ActionChip(
                    avatar: Icon(icon, size: 18),
                    label: Text(label),
                    onPressed: () => open(target),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
