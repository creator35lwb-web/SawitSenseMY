"""Tests for the MPOB Prestasi Sawit OER collector.

Author: QQ (Perplexity) — recovery patch (May 2026)
Patch: SS (Claude Code), Sep 2026 — fixture recorded from the live API;
state-code and cross-check tests.
"""

import copy
import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from scrapers.mpob_oer import (
    MPOBOERScraper,
    STATE_REGION_MAP,
    _cross_check,
    _weighted_region_average,
    StateOER,
)


# Real response for August 2026 (performance + state tables only).
SAMPLE_PAYLOAD = json.loads(
    (Path(__file__).parent / "fixtures" / "mpob_oer_2026_08.json").read_text(encoding="utf-8")
)


def _row(payload: dict, code: str) -> dict:
    return next(r for r in payload["state_data"] if r["negeri"] == code)


def _swapped_east_malaysia_payload() -> dict:
    """What the API would look like if MPOB swapped the Sabah/Sarawak codes."""
    payload = copy.deepcopy(SAMPLE_PAYLOAD)
    _row(payload, "13")["negeri"] = "tmp"
    _row(payload, "14")["negeri"] = "13"
    _row(payload, "tmp")["negeri"] = "14"
    return payload


class TestStateRegionMap:
    def test_all_states_present(self):
        # 11 Peninsular states + Sabah + Sarawak.
        assert len(STATE_REGION_MAP) == 13

    def test_sabah_sarawak_use_mpob_codes(self):
        # MPOB: Sabah = 13, Sarawak = 14 (not the JPN/ISO 12 / 13).
        assert STATE_REGION_MAP["13"] == ("Sabah", "Sabah")
        assert STATE_REGION_MAP["14"] == ("Sarawak", "Sarawak")
        assert "12" not in STATE_REGION_MAP

    def test_johor_is_south(self):
        assert STATE_REGION_MAP["01"][1] == "South"

    def test_every_code_in_live_response_is_mapped(self):
        codes = {r["negeri"] for r in SAMPLE_PAYLOAD["state_data"]}
        assert codes <= set(STATE_REGION_MAP)


class TestWeightedRegionAverage:
    def test_single_state_region(self):
        states = [StateOER("13", "Sabah", "Sabah", "2026", "04", 21.54, 0, 80000, 370000)]
        out = _weighted_region_average(states)
        assert out == {"Sabah": 21.54}

    def test_multi_state_weighted(self):
        # South region: Johor + Melaka (different OERs, different FFB volumes)
        states = [
            StateOER("01", "Johor",  "South", "2026", "04", 20.0, 0, 0, 1000000),
            StateOER("04", "Melaka", "South", "2026", "04", 22.0, 0, 0, 1000000),
        ]
        out = _weighted_region_average(states)
        assert out["South"] == pytest.approx(21.0)  # equal-weighted because FFB equal

    def test_zero_ffb_falls_back_to_equal_weight(self):
        states = [
            StateOER("01", "Johor",  "South", "2026", "04", 20.0, 0, 0, 0),
            StateOER("04", "Melaka", "South", "2026", "04", 21.0, 0, 0, 0),
        ]
        assert _weighted_region_average(states) == {"South": 20.5}


class TestCrossCheck:
    def test_live_payload_reconciles_with_mpob_totals(self):
        scraper = MPOBOERScraper()
        with patch.object(scraper.session, "get", return_value=_resp(SAMPLE_PAYLOAD)):
            snap = scraper.scrape(year=2026, month=8)
        assert _cross_check(snap.states, SAMPLE_PAYLOAD["performance_data"][0]) == []

    def test_swapped_codes_are_detected(self):
        scraper = MPOBOERScraper()
        with patch.object(scraper.session, "get", return_value=_resp(_swapped_east_malaysia_payload())):
            snap = scraper.scrape(year=2026, month=8)
        assert len(snap.warnings) == 2
        assert any("Sabah" in w for w in snap.warnings)
        assert any("Sarawak" in w for w in snap.warnings)
        # Unreconciled per-region figures are withheld, so run_scraper falls
        # back to MPOB's own published Sabah / Sarawak / Peninsular OER.
        assert snap.region_avg == {}


def _resp(payload, status=200):
    m = MagicMock()
    m.status_code = status
    m.json = MagicMock(return_value=payload)
    m.raise_for_status = MagicMock()
    return m


class TestScraperFlow:
    def test_happy_path(self):
        scraper = MPOBOERScraper()
        with patch.object(scraper.session, "get", return_value=_resp(SAMPLE_PAYLOAD)):
            snap = scraper.scrape(year=2026, month=8)
        assert snap is not None
        assert snap.year == 2026
        assert snap.month == 8
        assert snap.oer_malaysia == pytest.approx(20.01)
        assert snap.mill_count == 451
        assert len(snap.states) == 12
        assert snap.warnings == []
        # Each East Malaysian region must equal MPOB's own published figure.
        assert snap.region_avg["Sabah"] == pytest.approx(snap.oer_sabah)
        assert snap.region_avg["Sarawak"] == pytest.approx(snap.oer_sarawak)
        assert snap.region_avg["Sarawak"] == pytest.approx(19.58)

    def test_unknown_state_code_with_volume_warns(self):
        payload = copy.deepcopy(SAMPLE_PAYLOAD)
        payload["state_data"].append(
            {"negeri": "15", "tahun": "2026", "bulan": "08", "oer_cpo": 20.0,
             "oer_cpko": 0, "cpo_proc": 1000.0, "ffb_proc": 5000.0}
        )
        scraper = MPOBOERScraper()
        with patch.object(scraper.session, "get", return_value=_resp(payload)):
            snap = scraper.scrape(year=2026, month=8)
        assert len(snap.states) == 12
        assert any("unknown state code '15'" in w for w in snap.warnings)

    def test_empty_payload_falls_back(self):
        scraper = MPOBOERScraper()
        empty = {"performance_data": [], "state_data": []}
        with patch.object(scraper.session, "get", return_value=_resp(empty)):
            # All 3 attempts return empty -> None
            assert scraper.scrape(year=2026, month=4) is None

    def test_network_error_returns_none(self):
        import requests
        scraper = MPOBOERScraper(max_retries=1)
        with patch.object(scraper.session, "get", side_effect=requests.ConnectionError("boom")):
            assert scraper.scrape(year=2026, month=4) is None
