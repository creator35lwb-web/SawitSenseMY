// Where the Share panel can send the site's link. The link is the plain site
// address, with no tracking. There is no Telegram option: SawitSense has no
// channel there.
//
// Author: SS (Claude Code), Oct 2026

enum ShareTarget { whatsapp, facebook, x, linkedin, email }

/// The address that opens [target]'s own share screen with [text] and [url].
Uri shareLink(
  ShareTarget target, {
  required String text,
  required String url,
  required String emailSubject,
}) {
  final u = Uri.encodeComponent(url);
  final t = Uri.encodeComponent(text);
  return Uri.parse(switch (target) {
    ShareTarget.whatsapp =>
      'https://wa.me/?text=${Uri.encodeComponent('$text $url')}',
    ShareTarget.facebook => 'https://www.facebook.com/sharer/sharer.php?u=$u',
    ShareTarget.x => 'https://x.com/intent/tweet?text=$t&url=$u',
    ShareTarget.linkedin =>
      'https://www.linkedin.com/sharing/share-offsite/?url=$u',
    ShareTarget.email => 'mailto:?subject=${Uri.encodeComponent(emailSubject)}'
        '&body=${Uri.encodeComponent('$text\n\n$url')}',
  });
}
