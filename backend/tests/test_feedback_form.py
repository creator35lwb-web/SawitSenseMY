"""Tests for the feedback form watchdog.

The form page is built here in the shape Google serves it, so the tests never
contact Google and never submit anything.

Author: SS (Claude Code), Oct 2026
"""

import json
import urllib.error
from unittest.mock import patch

from monitor import feedback_form
from monitor.feedback_form import (
    LINKS_FILE,
    FEEDBACK_LINK_FILE,
    expected_from_app,
    find_problems,
    form_fields,
)

OPEN_URL = "https://docs.google.com/forms/d/e/FORM/viewform"
HELPFUL = "Ini berguna · This is helpful · 很有帮助"
CONFUSING = "Sesuatu mengelirukan · Something is confusing · 有些地方看不懂"
WRONG = "Harga nampak salah · A price looks wrong · 价格好像不对"

EXPECTED = {
    "url": OPEN_URL,
    "topic_field": 2059050621,
    "details_field": 1276594150,
    "options": [HELPFUL, CONFUSING, WRONG],
}


def _page(topic_options=(HELPFUL, CONFUSING, WRONG, "Cadangan · An idea · 建议"),
          topic_field=2059050621, details_field=1276594150) -> str:
    """A form page shaped like Google's: questions in FB_PUBLIC_LOAD_DATA_[1][1]."""
    questions = [
        [1079885817, "Rating", None, 18, [[1400080953, [[str(n)] for n in range(1, 6)], 1]]],
        [1030814783, "Topic", None, 2, [[topic_field, [[o, None, None, None, False] for o in topic_options], 1]]],
        [9803300, "Tell us more", None, 1, [[1450778564, None, 0]]],
        [1828444345, "App details", None, 0, [[details_field, None, 0]]],
    ]
    data = [None, [None, questions]]
    return f"<html><script>var FB_PUBLIC_LOAD_DATA_ = {json.dumps(data)};</script></html>"


class TestExpectedFromApp:
    def test_reads_what_the_app_actually_sends(self):
        # The real app source: if links.dart or FeedbackTopic changes, the
        # watchdog follows without an edit here.
        expected = expected_from_app(LINKS_FILE.read_text(encoding="utf-8"),
                                     FEEDBACK_LINK_FILE.read_text(encoding="utf-8"))
        assert expected["url"].startswith("https://docs.google.com/forms/")
        assert expected["topic_field"] == 2059050621
        assert expected["details_field"] == 1276594150
        assert expected["options"] == [HELPFUL, CONFUSING, WRONG]


class TestFormFields:
    def test_maps_field_ids_to_options(self):
        fields = form_fields(_page())
        assert fields[2059050621][:3] == [HELPFUL, CONFUSING, WRONG]
        assert fields[1276594150] == []
        assert fields[1400080953] == ["1", "2", "3", "4", "5"]


class TestFindProblems:
    def test_form_that_matches_the_app(self):
        assert find_problems(OPEN_URL, _page(), EXPECTED) == []

    def test_closed_form(self):
        html = "<html>This form is no longer accepting responses</html>"
        problems = find_problems(OPEN_URL.replace("viewform", "closedform"), html, EXPECTED)
        assert len(problems) == 1
        assert "no longer accepting responses" in problems[0]

    def test_form_that_asks_readers_to_sign_in(self):
        problems = find_problems("https://accounts.google.com/v3/signin/identifier?continue=x", "", EXPECTED)
        assert len(problems) == 1
        assert "sign in" in problems[0]

    def test_reworded_option(self):
        page = _page(topic_options=(HELPFUL, CONFUSING, "Harga salah · Wrong price · 价格不对"))
        problems = find_problems(OPEN_URL, page, EXPECTED)
        assert len(problems) == 1
        assert WRONG in problems[0]

    def test_recreated_topic_question(self):
        problems = find_problems(OPEN_URL, _page(topic_field=111), EXPECTED)
        assert len(problems) == 1
        assert "entry.2059050621" in problems[0]

    def test_recreated_app_details_field(self):
        problems = find_problems(OPEN_URL, _page(details_field=222), EXPECTED)
        assert len(problems) == 1
        assert "entry.1276594150" in problems[0]

    def test_page_google_changed_beyond_recognition(self):
        problems = find_problems(OPEN_URL, "<html>new layout</html>", EXPECTED)
        assert len(problems) == 1
        assert "Could not read" in problems[0]


class TestMain:
    def test_passes_when_the_form_matches(self):
        with patch.object(feedback_form, "fetch", return_value=(OPEN_URL, _page())):
            assert feedback_form.main() == 0

    def test_fails_when_the_form_cannot_be_reached(self):
        with patch.object(feedback_form, "fetch", side_effect=urllib.error.URLError("offline")):
            assert feedback_form.main() == 1

    def test_never_submits(self):
        # Only the form's page is fetched: a test response would land in
        # Alton's sheet as feedback.
        with patch.object(feedback_form, "fetch", return_value=(OPEN_URL, _page())) as fetch:
            feedback_form.main()
        (url,), _ = fetch.call_args
        assert url.endswith("/viewform")
        assert "formResponse" not in url
