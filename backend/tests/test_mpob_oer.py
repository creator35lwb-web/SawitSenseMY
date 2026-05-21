"""Tests for the MPOB Prestasi Sawit OER collector.

Author: QQ (Perplexity) \u2014 recovery patch (May 2026)
"""

from unittest.mock import MagicMock, patch

import pytest

from scrapers.mpob_oer import (
    MPOBOERScraper,
    STATE_REGION_MAP,
    _weighted_region_average,
    StateOER,
)


SAMPLE_PAYLOAD = {
    "performance_data": [{
        "oer_malaysia": 20.49,
        "oer_peninsular": 20.10,
        "oer_sabah": 21.54,
        "oer_sarawak": 20.42,
        "max_pelesen": 24.59,
        "min_pelesen": 13.09,
        "mill_count": 450,
    }],
    "state_data": [
        {"negeri": "01", "tahun": "2026", "bulan": "04", "oer_cpo": 20.24, "oer_cpko": 46.57, "cpo_proc": 253959.19, "ffb_proc": 1254710},
        {"negeri": "06", "tahun": "2026", "bulan": "04", "oer_cpo": 19.80, "oer_cpko": 0, "cpo_proc": 100000, "ffb_proc": 500000},
        {"negeri": "12", "tahun": "2026", "bulan": "04", "oer_cpo": 21.54, "oer_cpko": 0, "cpo_proc": 80000, "ffb_proc": 370000},
        {"negeri": "13", "tahun": "2026", "bulan": "04", "oer_cpo": 20.42, "oer_cpko": 0, "cpo_proc": 70000, "ffb_proc": 340000},
    ],
    "district_data": [], "pelesen_data": [], "min_max": [],
}


class TestStateRegionMap:
    def test_all_states_present(self):
        # Sanity: 13 Malaysian states represented in our map.
        assert len(STATE_REGION_MAP) == 13

    def test_sabah_sarawak_correct(self):
        assert STATE_REGION_MAP["12"][1] == "Sabah"
        assert STATE_REGION_MAP["13"][1] == "Sarawak"

    def test_johor_is_south(self):
        assert STATE_REGION_MAP["01"][1] == "South"


class TestWeightedRegionAverage:
    def test_single_state_region(self):
        states = [StateOER("12", "Sabah", "Sabah", "2026", "04", 21.54, 0, 80000, 370000)]
        out = _weighted_region_average(states)
        assert out == {"Sabah": 21.54}

    def test_multi_state_weighted(self):
        # South region: Johor + Melaka (different OERs, different FFB volumes)
        states = [
            StateOER("01", "Johor",  "South", "2026", "04", 20.0, 0, 0, 1000000),
            StateOER("04", "Melaka", "South", "2026", "04", 22.0, 0, 0, 1000000),
        ]
        out = _weighted_region_average(states)
        assert out["South"] == 21.0  # equal-weighted because FFB equal


class TestScraperFlow:
    def _resp(self, payload, status=200):
        m = MagicMock()
        m.status_code = status
        m.json = MagicMock(return_value=payload)
        m.raise_for_status = MagicMock()
        return m

    def test_happy_path(self):
        scraper = MPOBOERScraper()
        with patch.object(scraper.session, "get", return_value=self._resp(SAMPLE_PAYLOAD)):
            snap = scraper.scrape(year=2026, month=4)
        assert snap is not None
        assert snap.year == 2026
        assert snap.month == 4
        assert snap.oer_malaysia == 20.49
        assert snap.mill_count == 450
        assert len(snap.states) == 4
        # Sabah region average must equal Sabah state OER
        assert snap.region_avg["Sabah"] == 21.54
        # Sarawak region average must equal Sarawak state OER
        assert snap.region_avg["Sarawak"] == 20.42

    def test_empty_payload_falls_back(self):
        scraper = MPOBOERScraper()
        empty = {"performance_data": [], "state_data": []}
        with patch.object(scraper.session, "get", return_value=self._resp(empty)):
            # All 3 attempts return empty -> None
            assert scraper.scrape(year=2026, month=4) is None

    def test_network_error_returns_none(self):
        import requests
        scraper = MPOBOERScraper(max_retries=1)
        with patch.object(scraper.session, "get", side_effect=requests.ConnectionError("boom")):
            assert scraper.scrape(year=2026, month=4) is None
