"""Tests for health monitoring.

Author: QQ (Qoder CSO)
"""

import pytest
from datetime import datetime, timezone, timedelta
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

    def test_no_data(self):
        result = get_data_freshness(None)
        assert result["status"] == "RED"
