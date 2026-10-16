"""Feedback form watchdog for SawitSense.

The app's Feedback button opens Alton's Google Form with the reader's choice
selected and the app details filled in (D14). That only works while the form
matches the app: if a question is recreated its field ID changes, and if an
option is reworded the form opens with nothing selected. Either way readers
can still send feedback, but the link silently degrades, and a closed form
loses feedback altogether.

This opens the public form the way a reader's browser does and checks:
  - it is accepting responses and needs no sign-in;
  - the fields the app fills in still exist;
  - every option the app can select is still offered, word for word.

It never submits: a test response would land in Alton's sheet as feedback.
What the app expects is read from the app's own source
(frontend/lib/config/links.dart and frontend/lib/services/feedback_link.dart),
so there is one place to change.

Exit code 0 = the form matches the app, 1 = a problem (the workflow then
files an alert issue).

Author: SS (Claude Code), Oct 2026
"""

import json
import re
import sys
import urllib.request
from pathlib import Path

FRONTEND = Path(__file__).parent.parent.parent / "frontend" / "lib"
LINKS_FILE = FRONTEND / "config" / "links.dart"
FEEDBACK_LINK_FILE = FRONTEND / "services" / "feedback_link.dart"

_LOAD_DATA = re.compile(r"var FB_PUBLIC_LOAD_DATA_ = (.*?);\s*</script>", re.S)


def expected_from_app(links_src: str, feedback_src: str) -> dict:
    """What the app sends: the form URL, the fields it fills, the options it selects."""
    def const(name: str) -> str:
        m = re.search(rf"const String {name} =\s*'([^']+)';", links_src)
        if not m:
            raise ValueError(f"{name} not found in links.dart")
        return m.group(1)

    enum = re.search(r"enum FeedbackTopic \{(.*?);", feedback_src, re.S)
    if not enum:
        raise ValueError("enum FeedbackTopic not found in feedback_link.dart")
    options = re.findall(r"\w+\('([^']+)'\)", enum.group(1))
    if not options:
        raise ValueError("FeedbackTopic has no options")
    return {
        "url": const("feedbackFormUrl"),
        "topic_field": int(const("feedbackTopicField").removeprefix("entry.")),
        "details_field": int(const("feedbackAppDetailsField").removeprefix("entry.")),
        "options": options,
    }


def form_fields(html: str) -> dict:
    """Map each field ID in the public form to its option texts ([] for text fields).

    Google embeds the form's structure in the page as FB_PUBLIC_LOAD_DATA_:
    data[1][1] lists the questions, and each question's [4] lists its fields
    as [field_id, [[option_text, ...], ...], required, ...].
    """
    m = _LOAD_DATA.search(html)
    if not m:
        raise ValueError("the page has no form data")
    data = json.loads(m.group(1))
    fields = {}
    for item in data[1][1] or []:
        for field in (item[4] if len(item) > 4 and item[4] else []):
            fields[field[0]] = [opt[0] for opt in (field[1] or [])]
    return fields


def find_problems(final_url: str, html: str, expected: dict) -> list:
    """Return human-readable problems; an empty list means the form matches the app."""
    if "accounts.google.com" in final_url:
        return ["The form now asks readers to sign in to Google. "
                "Turn off 'Limit to 1 response' and 'Collect email addresses' (docs/feedback-form.md)."]
    if "closedform" in final_url or "no longer accepting responses" in html:
        return ["The form is no longer accepting responses, so readers' feedback is lost. "
                "Turn 'Accepting responses' back on in the form's Responses tab."]
    try:
        fields = form_fields(html)
    except (ValueError, IndexError, TypeError) as e:
        return [f"Could not read the form's questions ({e}). Google may have changed the page."]

    problems = []
    if expected["details_field"] not in fields:
        problems.append(f"The 'App details' field entry.{expected['details_field']} is gone, "
                        "so feedback arrives without the version and price time. "
                        "Update feedbackAppDetailsField in frontend/lib/config/links.dart.")
    if expected["topic_field"] not in fields:
        problems.append(f"The topic question entry.{expected['topic_field']} is gone, "
                        "so the app's choice is no longer selected. "
                        "Update feedbackTopicField in frontend/lib/config/links.dart.")
    else:
        offered = fields[expected["topic_field"]]
        for option in expected["options"]:
            if option not in offered:
                problems.append(f"The form no longer offers the option '{option}', so it opens "
                                "with nothing selected. Make the wording match FeedbackTopic in "
                                "frontend/lib/services/feedback_link.dart.")
    return problems


def fetch(url: str, timeout: int = 30):
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (SawitSense feedback-form watchdog)",
        "Accept-Language": "en",
    })
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.geturl(), resp.read().decode("utf-8", errors="replace")


def main() -> int:
    expected = expected_from_app(LINKS_FILE.read_text(encoding="utf-8"),
                                 FEEDBACK_LINK_FILE.read_text(encoding="utf-8"))
    try:
        final_url, html = fetch(expected["url"])
    except OSError as e:  # URLError, HTTPError and timeouts are OSErrors
        print(f"::error::Could not open the feedback form: {e}")
        return 1

    problems = find_problems(final_url, html, expected)
    for problem in problems:
        print(f"::error::{problem}")
    if problems:
        return 1
    print(f"The feedback form is open and matches the app "
          f"({len(expected['options'])} options, fields entry.{expected['topic_field']} "
          f"and entry.{expected['details_field']}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
