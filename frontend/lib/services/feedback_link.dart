// The link that opens the feedback form (D14) with the reader's choice and
// the app details already filled in. Only the app version, the language and
// the time of the prices on screen are sent: no personal data.
//
// Author: SS (Claude Code), Oct 2026

import '../config/links.dart';

enum FeedbackTopic {
  helpful('Ini berguna · This is helpful · 很有帮助'),
  confusing('Sesuatu mengelirukan · Something is confusing · 有些地方看不懂'),
  wrongPrice('Harga nampak salah · A price looks wrong · 价格好像不对');

  const FeedbackTopic(this.formOption);

  /// The option's exact text in the form. It must match, or the form opens
  /// with nothing selected.
  final String formOption;
}

/// What the form's "App details" field shows, e.g.
/// "v0.3.12 · zh · prices 2026-10-01T13:45:04+08:00". It lets a "price looks
/// wrong" report be checked against the exact data the reader saw.
String feedbackAppDetails({
  required String version,
  required String language,
  String? pricesScrapedAt,
}) =>
    'v$version · $language · prices ${pricesScrapedAt ?? 'not loaded'}';

/// The form, opened with [topic] selected and [appDetails] filled in.
Uri feedbackFormLink(FeedbackTopic topic, {required String appDetails}) =>
    Uri.parse(feedbackFormUrl).replace(queryParameters: {
      'usp': 'pp_url',
      feedbackTopicField: topic.formOption,
      feedbackAppDetailsField: appDetails,
    });
