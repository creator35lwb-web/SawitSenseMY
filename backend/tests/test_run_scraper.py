"""Tests for the orchestrator's indicative-derivation logic.

Author: QQ (Perplexity) \u2014 recovery patch (May 2026)
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest

from run_scraper import build_payload, decide_payload, indicative_price_1pct  # noqa: E402
from scrapers.mpoc_cpo import MPOCDailyCPO
from scrapers.mpob_oer import OERSnapshot, StateOER


class TestIndicativePrice1Pct:
    def test_readme_south_example(self):
        # README South-region example: CPO ~RM 2,624 -> Price_1% \u2248 RM 24.40
        # With share factor 0.93, 2624 * 0.01 * 0.93 = 24.40
        p1 = indicative_price_1pct(2624)
        assert abs(p1 - 24.40) < 0.05

    def test_zero_cpo(self):
        assert indicative_price_1pct(0) == pytest.approx(0.0)

    def test_negative_cpo_rejected(self):
        assert indicative_price_1pct(-100) == pytest.approx(0.0)


class TestBuildPayload:
    def _make_cpo(self, price=4583.0, date_iso="2026-05-20"):
        return MPOCDailyCPO(date_iso=date_iso, date_raw="20 May 26", price_myr_per_tonne=price)

    def _make_oer(self):
        states = [
            StateOER("01", "Johor",  "South",      "2026", "04", 20.24, 0, 0, 1254710),
            StateOER("06", "Pahang", "East Coast", "2026", "04", 19.80, 0, 0, 500000),
            StateOER("13", "Sabah",  "Sabah",      "2026", "04", 21.54, 0, 0, 370000),
            StateOER("14", "Sarawak","Sarawak",    "2026", "04", 20.42, 0, 0, 340000),
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
        assert payload["cpo"]["price_myr_per_tonne"] == pytest.approx(4583.0)
        assert payload["oer"]["oer_malaysia"] == pytest.approx(20.49)
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
        assert payload["cpo"]["price_myr_per_tonne"] == pytest.approx(4500.0)


class TestWarnings:
    """Data-quality warnings that the scraper workflow turns into an alert."""

    def test_clean_run_has_no_warnings(self):
        payload = build_payload(TestBuildPayload()._make_cpo(), TestBuildPayload()._make_oer(), False, None)
        assert payload["warnings"] == []

    def test_missing_sources_are_reported(self):
        payload = build_payload(None, None, False, None)
        assert any("MPOC daily CPO price unavailable" in w for w in payload["warnings"])
        assert any("MPOB OER data unavailable" in w for w in payload["warnings"])

    def test_oer_snapshot_warnings_are_carried_over(self):
        oer = TestBuildPayload()._make_oer()
        oer.warnings = ["MPOB OER cross-check failed for Sarawak: ..."]
        payload = build_payload(TestBuildPayload()._make_cpo(), oer, False, None)
        assert payload["warnings"] == oer.warnings

    def test_withheld_region_averages_fall_back_to_mpob_totals(self):
        # When the cross-check fails, mpob_oer withholds region_avg; every
        # region must then use MPOB's own published figure.
        oer = TestBuildPayload()._make_oer()
        oer.region_avg = {}
        payload = build_payload(TestBuildPayload()._make_cpo(), oer, False, None)
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert regions["Sabah"]["indicative_oer_pct"] == pytest.approx(21.54)
        assert regions["Sarawak"]["indicative_oer_pct"] == pytest.approx(20.42)
        assert regions["North"]["indicative_oer_pct"] == pytest.approx(20.10)


class TestVerifiableSources:
    """The payload must let anyone check each figure against a public page."""

    def _payload(self):
        return build_payload(TestBuildPayload()._make_cpo(), TestBuildPayload()._make_oer(), False, None)

    def test_share_factor_is_published_and_reproduces_price_1pct(self):
        payload = self._payload()
        factor = payload["ffb"]["indicative_share_factor"]
        assert factor == pytest.approx(0.93)
        cpo = payload["cpo"]["price_myr_per_tonne"]
        for region in payload["ffb"]["regions"]:
            assert region["price_1pct_oer"] == pytest.approx(round(cpo * 0.01 * factor, 2))

    def test_cpo_links_to_the_public_mpoc_page(self):
        assert self._payload()["cpo"]["source_url"] == "https://mpoc.org.my/daily-palm-oil-prices/"

    def test_oer_links_to_the_public_mpob_page_not_the_api(self):
        oer = self._payload()["oer"]
        assert oer["source_page_url"] == "https://prestasisawit.mpob.gov.my/en/oer"
        assert "/api/" not in oer["source_page_url"]


class TestKeepLastGoodData:
    """K7: a failed source never replaces the last good data."""

    PREVIOUS = {
        "cpo": {"date": "2026-09-28", "price_myr_per_tonne": 4664.0},
        "oer": {
            "year": 2026, "month": 4,
            "oer_malaysia": 20.49, "oer_peninsular": 20.10,
            "oer_sabah": 21.54, "oer_sarawak": 20.42,
            "region_avg": {"South": 20.24, "Sabah": 21.54, "Sarawak": 20.42},
        },
    }

    def test_no_cpo_keeps_the_last_snapshot(self):
        oer = TestBuildPayload()._make_oer()
        assert decide_payload(None, oer, False, None, self.PREVIOUS) is None

    def test_fallback_cpo_still_publishes(self):
        fb = {"date": "2026-09-28", "price_myr_per_tonne": 4600.0, "source": "Commodities-API (fallback)"}
        payload = decide_payload(None, None, False, fb, self.PREVIOUS)
        assert payload is not None
        assert payload["fallback_used"] is True

    def test_missing_oer_is_carried_forward_and_flagged(self):
        payload = decide_payload(TestBuildPayload()._make_cpo(), None, False, None, self.PREVIOUS)
        assert payload["oer"]["carried_forward"] is True
        assert payload["oer"]["month"] == 4
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert regions["Sarawak"]["indicative_oer_pct"] == pytest.approx(20.42)
        assert any("kept the previous figures (2026-04)" in w for w in payload["warnings"])

    def test_missing_oer_without_history_publishes_without_regional_oer(self):
        payload = decide_payload(TestBuildPayload()._make_cpo(), None, False, None, None)
        assert payload["oer"] is None
        assert all(r["indicative_oer_pct"] is None for r in payload["ffb"]["regions"])
        assert any("no regional OER" in w for w in payload["warnings"])

    def test_fresh_oer_is_never_marked_carried_forward(self):
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, self.PREVIOUS)
        assert "carried_forward" not in payload["oer"]


class TestMainKeepsLastSnapshot:
    def test_run_without_cpo_writes_nothing_and_fails(self, monkeypatch):
        import run_scraper
        from types import SimpleNamespace

        writes = []
        monkeypatch.setattr(run_scraper, "MPOBScraper", lambda: SimpleNamespace(scrape_all=lambda: {"success": False}))
        monkeypatch.setattr(run_scraper, "MPOCDailyCPOScraper", lambda: SimpleNamespace(scrape=lambda: None))
        monkeypatch.setattr(run_scraper, "MPOBOERScraper", lambda: SimpleNamespace(scrape=lambda: None))
        monkeypatch.setattr(run_scraper, "fetch_cpo_fallback", lambda: None)
        monkeypatch.setattr(run_scraper, "read_latest", lambda: TestKeepLastGoodData.PREVIOUS)
        monkeypatch.setattr(run_scraper, "write_price_data", lambda payload: writes.append(payload) or True)
        monkeypatch.setattr(run_scraper, "report_failure", lambda msg="": {})
        monkeypatch.setattr(run_scraper, "report_success", lambda: {})

        assert run_scraper.main() == 1
        assert writes == []  # latest.json is left as it was
