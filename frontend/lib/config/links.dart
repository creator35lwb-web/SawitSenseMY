// Public links used across the app. Links to official data sources come from
// the price data itself (`source_url`, `source_page_url`); these are the
// project's own pages.
//
// Author: SS (Claude Code), Sep 2026

/// How SawitSense derives its indicative prices (ADR-001).
const String adrUrl =
    'https://github.com/creator35lwb-web/SawitSenseMY/blob/main/docs/ADR-001-mpob-data-source-change.md';

/// Every price snapshot SawitSense has published (open data).
const String openDataUrl =
    'https://github.com/creator35lwb-web/SawitSenseMY/tree/main/backend/data';

/// The live site. Shared as it is: no tracking parameters.
const String siteUrl = 'https://creator35lwb-web.github.io/SawitSenseMY/';

/// The feedback form (D14): a Google Form Alton owns. It is anonymous and
/// needs no sign-in; see docs/feedback-form.md.
const String feedbackFormUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSf0oHnG7Xx4zGcCHuB9xgeGDGcL0Y2PKDbOVHMVaQ8XvkKCyQ/viewform';

/// The form's fields the app fills in, from its pre-filled link.
const String feedbackTopicField = 'entry.2059050621';
const String feedbackAppDetailsField = 'entry.1276594150';

/// MPOB's daily round-up of palm oil news from the Malaysian press, and
/// MPOB's own press releases: the "Latest from MPOB" card links to both
/// (D18). SawitSense links to them and never copies the news itself.
const String mpobNewsUrl = 'https://mpob.gov.my/current-news/';
const String mpobPressUrl = 'https://mpob.gov.my/press-release/';

/// MPOB's daily FFB reference price summary for the month holding [time]
/// (D22): a public PDF with every trading day so far, by region. The prices
/// carry the exact link they were read from; this is for when they don't.
String mpobFfbPdfUrl(DateTime time) {
  final myt = time.toUtc().add(const Duration(hours: 8));
  String two(int n) => n.toString().padLeft(2, '0');
  return 'https://price.mpob.gov.my/pdf/daily/ffb/'
      '${myt.year}-${two(myt.month)}-${two(myt.day)}';
}
