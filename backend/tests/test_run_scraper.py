"""Tests for the orchestrator's indicative-derivation logic.

Author: QQ (Perplexity) \u2014 recovery patch (May 2026)
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from run_scraper import build_payload, indicative_price_1pct, DEFAULT_INDICATIVE_SHARE_FACTOR
from scrapers.mpoc_cpo import MPOCDailyCPO
from scrapers.mpob_oer import OERSnapshot, StateOER


class TestIndicativePrice1Pct:
    def test_readme_south_example(self):
        # README South-region example: CPO ~RM 2,624 -> Price_1% \u2248 RM 24.40
        # With share factor 0.93, 2624 * 0.01 * 0.93 = 24.40
        p1 = indicative_price_1pct(2624)
        assert abs(p1 - 24.40) < 0.05

    def test_zero_cpo(self):
        assert indicative_price_1pct(0) == 0.0

    def test_negative_cpo_rejected(self):
        assert indicative_price_1pct(-100) == 0.0


class TestBuildPayload:
    def _make_cpo(self, price=4583.0, date_iso="2026-05-20"):
        return MPOCDailyCPO(date_iso=date_iso, date_raw="20 May 26", price_myr_per_tonne=price)

    def _make_oer(self):
        states = [
            StateOER("01", "Johor",  "South",      "2026", "04", 20.24, 0, 0, 1254710),
            StateOER("06", "Pahang", "East Coast", "2026", "04", 19.80, 0, 0, 500000),
            StateOER("12", "Sabah",  "Sabah",      "2026", "04", 21.54, 0, 0, 370000),
            StateOER("13", "Sarawak","Sarawak",    "2026", "04", 20.42, 0, 0, 340000),
        ]
        from scrapers.mpob_oer import _weighted_region_average
        return OERSnapshot(
            year=2026, month=4,
            oer_malaysia=20.49, oer_peninsular=20.10,
            oer_sabah=21.54, oer_sarawak=20.42,
            mill_count=450, states=states,
            region_avg=_weighted_region_average(states),
        )

    def test_full_success_path(self):
        payload = build_payload(self._make_cpo(), self._make_oer(), False, None)
        assert payload["success"] is True
        assert payload["is_indicative"] is True
        assert payload["formula_status"] == "INDICATIVE"
        assert payload["cpo"]["price_myr_per_tonne"] == 4583.0
        assert payload["oer"]["oer_malaysia"] == 20.49
        assert payload["ffb"] is not None
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert set(regions.keys()) == {"North", "South", "Central", "East Coast", "Sabah", "Sarawak"}
        # All regions must carry the indicative flag
        for r in payload["ffb"]["regions"]:
            assert r["is_indicative"] is True

    def test_cpo_only_no_oer(self):
        payload = build_payload(self._make_cpo(), None, False, None)
        assert payload["success"] is True
        assert payload["cpo"] is not None
        # FFB regions still derived but with no per-region OER \u2014 must not crash
        assert payload["ffb"] is not None

    def test_all_failed_returns_unsuccessful(self):
        payload = build_payload(None, None, False, None)
        assert payload["success"] is False
        assert payload["cpo"] is None
        assert payload["oer"] is None
        assert payload["ffb"] is None

    def test_fallback_path(self):
        fb = {
            "date": "2026-05-20",
            "price_myr_per_tonne": 4500.0,
            "source": "Commodities-API (fallback)",
            "scraped_at": "2026-05-20T12:00:00+08:00",
        }
        payload = build_payload(None, None, False, fb)
        assert payload["success"] is True
        assert payload["fallback_used"] is True
        assert payload["cpo"]["price_myr_per_tonne"] == 4500.0
