"""Tests for health monitoring.

Author: QQ (Qoder CSO)
Patch: SS (Claude Code), Sep 2026 — test_no_data no longer reads the
committed health.json (it failed whenever the last scrape was < 12h old).
"""

import json
import logging
from datetime import datetime, timezone, timedelta
from monitor import health_check
from monitor.health_check import get_data_freshness

MYT = timezone(timedelta(hours=8))


class TestDataFreshness:
    def test_green(self):
        recent = datetime.now(MYT).isoformat()
        result = get_data_freshness(recent)
        assert result["status"] == "GREEN"

    def test_amber(self):
        nine_hours_ago = (datetime.now(MYT) - timedelta(hours=9)).isoformat()
        result = get_data_freshness(nine_hours_ago)
        assert result["status"] == "AMBER"

    def test_red(self):
        day_ago = (datetime.now(MYT) - timedelta(hours=24)).isoformat()
        result = get_data_freshness(day_ago)
        assert result["status"] == "RED"

    def test_no_data(self, tmp_path, monkeypatch):
        # Point the monitor at an empty data dir: with no health file there is
        # no last success, whatever the scraper last committed.
        monkeypatch.setattr(health_check, "HEALTH_FILE", tmp_path / "health.json")
        result = get_data_freshness(None)
        assert result["status"] == "RED"


class TestReportFailure:
    """Failures are counted, and text read from health.json never reaches the
    log (SonarCloud S5145, log injection)."""

    def test_counts_consecutive_failures(self, tmp_path, monkeypatch):
        monkeypatch.setattr(health_check, "HEALTH_FILE", tmp_path / "health.json")
        monkeypatch.setattr(health_check, "send_telegram_alert", lambda msg: False)
        assert health_check.report_failure("timeout")["consecutive_failures"] == 1
        assert health_check.report_failure("timeout")["consecutive_failures"] == 2

    def test_a_corrupted_count_restarts_and_never_reaches_the_log(
        self, tmp_path, monkeypatch, caplog
    ):
        health = tmp_path / "health.json"
        health.write_text(json.dumps({"consecutive_failures": "1\nFAKE: scrape SUCCESS"}))
        monkeypatch.setattr(health_check, "HEALTH_FILE", health)
        with caplog.at_level(logging.WARNING, logger="monitor.health_check"):
            state = health_check.report_failure("timeout")
        assert state["consecutive_failures"] == 1
        assert "FAKE" not in caplog.text
