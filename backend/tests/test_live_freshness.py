"""Tests for the live-site freshness watchdog.

Author: SS (Claude Code), Sep 2026
"""

import urllib.error
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from monitor import live_freshness
from monitor.live_freshness import find_problems

MYT = timezone(timedelta(hours=8))
NOW = datetime(2026, 9, 30, 12, 0, tzinfo=MYT)


def _snapshot(scraped_at: datetime) -> dict:
    return {"scraped_at": scraped_at.isoformat(), "success": True}


class TestFindProblems:
    def test_fresh_when_live_matches_main(self):
        snap = _snapshot(NOW - timedelta(hours=3))
        assert find_problems(snap, snap, NOW) == []

    def test_no_alert_while_deploy_is_within_grace_period(self):
        live = _snapshot(NOW - timedelta(hours=12))
        repo = _snapshot(NOW - timedelta(minutes=30))
        assert find_problems(live, repo, NOW) == []

    def test_alerts_when_live_site_is_behind_main(self):
        # The May-Sep 2026 incident: live frozen on 21 May, main current.
        live = _snapshot(datetime(2026, 5, 21, 16, 9, tzinfo=MYT))
        repo = _snapshot(NOW - timedelta(hours=5))
        problems = find_problems(live, repo, NOW)
        assert len(problems) == 1
        assert "has not been deployed" in problems[0]

    def test_alerts_when_main_data_is_too_old(self):
        snap = _snapshot(NOW - timedelta(days=5))
        problems = find_problems(snap, snap, NOW)
        assert len(problems) == 1
        assert "scraper may have stopped" in problems[0]

    def test_a_day_without_new_data_is_an_alarm(self):
        # Scrapes run every 2 hours, every day (D13): about 12 missed runs.
        snap = _snapshot(NOW - timedelta(hours=26))
        problems = find_problems(snap, snap, NOW)
        assert len(problems) == 1
        assert "26 hours ago" in problems[0]

    def test_late_runs_within_a_day_are_not_an_alarm(self):
        # GitHub starts scheduled runs hours late; that alone is not an alarm.
        snap = _snapshot(NOW - timedelta(hours=14))
        assert find_problems(snap, snap, NOW) == []

    def test_unreadable_timestamp_is_reported(self):
        problems = find_problems({}, {"scraped_at": "not-a-date"}, NOW)
        assert len(problems) == 1
        assert "unreadable" in problems[0]


class TestMain:
    def test_unreachable_live_site_fails(self, tmp_path, monkeypatch):
        latest = tmp_path / "latest.json"
        latest.write_text('{"scraped_at": "2026-09-30T08:00:00+08:00"}', encoding="utf-8")
        monkeypatch.setattr(live_freshness, "REPO_LATEST_FILE", latest)
        with patch.object(live_freshness, "fetch_live_snapshot",
                          side_effect=urllib.error.URLError("boom")):
            assert live_freshness.main() == 1

    def test_current_live_site_passes(self, tmp_path, monkeypatch):
        scraped_at = (datetime.now(MYT) - timedelta(hours=1)).isoformat()
        latest = tmp_path / "latest.json"
        latest.write_text(f'{{"scraped_at": "{scraped_at}"}}', encoding="utf-8")
        monkeypatch.setattr(live_freshness, "REPO_LATEST_FILE", latest)
        with patch.object(live_freshness, "fetch_live_snapshot",
                          return_value={"scraped_at": scraped_at}):
            assert live_freshness.main() == 0
