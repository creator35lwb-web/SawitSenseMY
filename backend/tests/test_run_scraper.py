"""Tests for the orchestrator: assembling the payload, MPOB's official prices
(D22), and keeping the last good data (K7).

Author: QQ (Perplexity) \u2014 recovery patch (May 2026)
Patch: SS (Claude Code), Oct 2026 \u2014 MPOB's daily FFB reference price replaces
the estimate (D22, K25)
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from datetime import datetime, timedelta, timezone

import pytest

from run_scraper import build_payload, decide_payload, ffb_quality_warnings, oer_in_app_since  # noqa: E402
from scrapers.mpob_ffb import FFBDailyPrices
from scrapers.mpoc_cpo import MPOCDailyCPO
from scrapers.mpob_oer import OERSnapshot, StateOER

MYT = timezone(timedelta(hours=8))
# MPOB's prices for 22 Oct 2026, per 1% OER at the mill gate.
MPOB_22_OCT = {"North": 47.82, "South": 48.20, "Central": 48.12,
               "East Coast": 48.08, "Sabah": 43.06, "Sarawak": 43.49}


def _make_ffb(day=None, prices=None, note="Miri & Bintulu"):
    """MPOB's daily prices as scrapers.mpob_ffb returns them; dated today unless given."""
    day = day or datetime.now(MYT).date().isoformat()
    prices = prices or dict(MPOB_22_OCT)
    return FFBDailyPrices(
        date_iso=day, prices=prices, dates={region: day for region in prices},
        year=int(day[:4]), month=int(day[5:7]),
        source_url=f"https://price.mpob.gov.my/pdf/daily/ffb/{day}",
        last_update=f"{day}T12:00:00+08:00", sarawak_note=note,
    )


class TestBuildPayload:
    def _make_cpo(self, price=4767.0, date_iso="2026-10-21"):
        return MPOCDailyCPO(date_iso=date_iso, date_raw="21 Oct 26", price_myr_per_tonne=price)

    def _make_oer(self):
        states = [
            StateOER("01", "Johor",  "South",      "2026", "04", 20.24, 0, 0, 1254710),
            StateOER("06", "Pahang", "East Coast", "2026", "04", 19.80, 0, 0, 500000),
            StateOER("13", "Sabah",  "Sabah",      "2026", "04", 21.54, 0, 0, 370000),
            StateOER("14", "Sarawak", "Sarawak",   "2026", "04", 20.42, 0, 0, 340000),
        ]
        from scrapers.mpob_oer import _weighted_region_average
        return OERSnapshot(
            year=2026, month=4,
            oer_malaysia=20.49, oer_peninsular=20.10,
            oer_sabah=21.54, oer_sarawak=20.42,
            mill_count=450, states=states,
            region_avg=_weighted_region_average(states),
        )

    def _payload(self):
        return build_payload(self._make_cpo(), self._make_oer(), False, None, ffb_obs=_make_ffb())

    def test_mpobs_official_prices_are_published(self):
        payload = self._payload()
        assert payload["success"] is True
        assert payload["is_indicative"] is False
        assert payload["formula_status"] == "OFFICIAL"
        assert payload["indicative_notice"] is None
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert list(regions) == ["North", "South", "Central", "East Coast", "Sabah", "Sarawak"]
        assert regions["South"]["price_1pct_oer"] == pytest.approx(48.20)
        assert regions["Sabah"]["price_1pct_oer"] == pytest.approx(43.06)
        assert all(r["is_indicative"] is False for r in regions.values())

    def test_regions_differ_as_mpobs_do(self):
        # The estimate gave every region the same price (K25).
        assert len({r["price_1pct_oer"] for r in self._payload()["ffb"]["regions"]}) == 6

    def test_each_region_carries_mpobs_average_oer(self):
        regions = {r["region"]: r for r in self._payload()["ffb"]["regions"]}
        assert regions["South"]["avg_oer_pct"] == pytest.approx(20.24)
        assert regions["Sabah"]["avg_oer_pct"] == pytest.approx(21.54)
        assert regions["North"]["avg_oer_pct"] == pytest.approx(20.10)  # MPOB's Peninsular figure

    def test_sarawak_says_which_towns_mpobs_price_is_for(self):
        regions = {r["region"]: r for r in self._payload()["ffb"]["regions"]}
        assert regions["Sarawak"]["note"] == "Miri & Bintulu"
        assert "note" not in regions["Sabah"]

    def test_no_estimate_is_published(self):
        ffb = self._payload()["ffb"]
        assert "indicative_share_factor" not in ffb
        assert all("indicative_fair_price_per_tonne" not in r for r in ffb["regions"])

    def test_cpo_only(self):
        payload = build_payload(self._make_cpo(), None, False, None)
        assert payload["success"] is True
        assert payload["cpo"] is not None
        assert payload["ffb"] is None

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
        assert TestBuildPayload()._payload()["warnings"] == []

    def test_missing_sources_are_reported(self):
        payload = build_payload(None, None, False, None)
        assert any("MPOC daily CPO price unavailable" in w for w in payload["warnings"])
        assert any("MPOB OER data unavailable" in w for w in payload["warnings"])
        assert any("MPOB daily FFB reference price unavailable" in w for w in payload["warnings"])

    def test_oer_snapshot_warnings_are_carried_over(self):
        maker = TestBuildPayload()
        oer = maker._make_oer()
        oer.warnings = ["MPOB OER cross-check failed for Sarawak: ..."]
        payload = build_payload(maker._make_cpo(), oer, False, None, ffb_obs=_make_ffb())
        assert payload["warnings"] == oer.warnings

    def test_withheld_region_averages_fall_back_to_mpob_totals(self):
        # When the cross-check fails, mpob_oer withholds region_avg; every
        # region must then use MPOB's own published figure.
        maker = TestBuildPayload()
        oer = maker._make_oer()
        oer.region_avg = {}
        payload = build_payload(maker._make_cpo(), oer, False, None, ffb_obs=_make_ffb())
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert regions["Sabah"]["avg_oer_pct"] == pytest.approx(21.54)
        assert regions["Sarawak"]["avg_oer_pct"] == pytest.approx(20.42)
        assert regions["North"]["avg_oer_pct"] == pytest.approx(20.10)


class TestFfbQualityWarnings:
    """Checks on each fresh read of MPOB's daily FFB summary (D22)."""

    def test_prices_in_line_with_cpo_pass(self):
        assert ffb_quality_warnings(_make_ffb(day="2026-10-22"), 4767.0, "2026-10-23") == []

    def test_a_week_old_price_is_flagged(self):
        warnings = ffb_quality_warnings(_make_ffb(day="2026-10-15"), 4767.0, "2026-10-23")
        assert warnings == ["MPOB's latest daily FFB price is from 2026-10-15, 8 days ago"]

    def test_a_long_holiday_weekend_is_not_flagged(self):
        # No trade on Saturday, then a Sunday and a Monday holiday.
        assert ffb_quality_warnings(_make_ffb(day="2026-10-16"), 4767.0, "2026-10-20") == []

    def test_a_price_far_from_the_cpo_price_is_flagged(self):
        ffb = _make_ffb(day="2026-10-22", prices={**MPOB_22_OCT, "North": 60.00})
        warnings = ffb_quality_warnings(ffb, 4767.0, "2026-10-23")
        assert warnings == ["MPOB's North price, RM 60.00 per 1% OER, is 126% of CPO x 0.01 "
                            "(CPO RM 4767); check it against MPOB's PDF"]

    def test_without_a_cpo_price_there_is_nothing_to_compare(self):
        ffb = _make_ffb(day="2026-10-22", prices={**MPOB_22_OCT, "North": 60.00})
        assert ffb_quality_warnings(ffb, None, "2026-10-23") == []

    def test_a_changed_sarawak_footnote_is_flagged(self):
        warnings = ffb_quality_warnings(_make_ffb(day="2026-10-22", note="Kuching"), 4767.0, "2026-10-23")
        assert warnings == ["MPOB's Sarawak footnote now reads 'Kuching'; update the app's wording"]


class TestVerifiableSources:
    """The payload must let anyone check each figure against a public page."""

    def _payload(self):
        return TestBuildPayload()._payload()

    def test_ffb_links_to_mpobs_daily_pdf(self):
        ffb = self._payload()["ffb"]
        assert ffb["source_url"].startswith("https://price.mpob.gov.my/pdf/daily/ffb/")
        assert ffb["source"] == "MPOB Daily FFB Reference Price (mill gate)"
        assert ffb["mpob_last_update"].endswith("+08:00")

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
        "ffb": {
            "date": "2026-10-21", "is_indicative": False,
            "source": "MPOB Daily FFB Reference Price (mill gate)",
            "regions": [{"region": "South", "price_1pct_oer": 48.12, "is_indicative": False}],
        },
    }
    # A snapshot from before D22, holding the estimate.
    BEFORE_D22 = {**PREVIOUS, "ffb": {
        "date": "2026-10-21", "is_indicative": True,
        "regions": [{"region": "South", "price_1pct_oer": 44.33, "is_indicative": True}],
    }}

    def test_no_cpo_keeps_the_last_snapshot(self):
        oer = TestBuildPayload()._make_oer()
        assert decide_payload(None, oer, False, None, self.PREVIOUS, ffb_obs=_make_ffb()) is None

    def test_fallback_cpo_still_publishes(self):
        fb = {"date": "2026-09-28", "price_myr_per_tonne": 4600.0, "source": "Commodities-API (fallback)"}
        payload = decide_payload(None, None, False, fb, self.PREVIOUS, ffb_obs=_make_ffb())
        assert payload is not None
        assert payload["fallback_used"] is True

    def test_missing_oer_is_carried_forward_and_flagged(self):
        payload = decide_payload(TestBuildPayload()._make_cpo(), None, False, None, self.PREVIOUS,
                                 ffb_obs=_make_ffb())
        assert payload["oer"]["carried_forward"] is True
        assert payload["oer"]["month"] == 4
        regions = {r["region"]: r for r in payload["ffb"]["regions"]}
        assert regions["Sarawak"]["avg_oer_pct"] == pytest.approx(20.42)
        assert any("kept the previous figures (2026-04)" in w for w in payload["warnings"])

    def test_missing_oer_without_history_publishes_without_regional_oer(self):
        payload = decide_payload(TestBuildPayload()._make_cpo(), None, False, None, None, ffb_obs=_make_ffb())
        assert payload["oer"] is None
        assert all(r["avg_oer_pct"] is None for r in payload["ffb"]["regions"])
        assert any("no regional OER" in w for w in payload["warnings"])

    def test_fresh_oer_is_never_marked_carried_forward(self):
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, self.PREVIOUS,
                                 ffb_obs=_make_ffb())
        assert "carried_forward" not in payload["oer"]

    def test_missing_mpob_prices_keep_the_last_ones_with_their_date(self):
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, self.PREVIOUS)
        assert payload["ffb"]["carried_forward"] is True
        assert payload["ffb"]["date"] == "2026-10-21"
        assert payload["formula_status"] == "OFFICIAL"
        assert any("kept the previous prices (2026-10-21)" in w for w in payload["warnings"])

    def test_missing_mpob_prices_without_history_publish_no_regional_prices(self):
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, None)
        assert payload["ffb"] is None
        assert any("no regional prices this run" in w for w in payload["warnings"])

    def test_the_estimate_stays_labelled_until_mpob_can_be_read(self):
        # The first run after D22, if MPOB doesn't answer.
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, self.BEFORE_D22)
        assert payload["is_indicative"] is True
        assert payload["formula_status"] == "INDICATIVE"
        assert "earlier estimate" in payload["indicative_notice"]

    def test_a_fresh_mpob_read_replaces_the_estimate(self):
        maker = TestBuildPayload()
        payload = decide_payload(maker._make_cpo(), maker._make_oer(), False, None, self.BEFORE_D22,
                                 ffb_obs=_make_ffb())
        assert payload["is_indicative"] is False
        assert "carried_forward" not in payload["ffb"]


class TestOerInAppSince:
    """D18: the app says which MPOB OER month is in the prices, and since when."""

    def _decide(self, previous):
        maker = TestBuildPayload()
        return decide_payload(maker._make_cpo(), maker._make_oer(), False, None, previous)

    def test_a_new_month_is_dated_today_in_malaysia(self):
        payload = self._decide({"oer": {"year": 2026, "month": 3, "in_app_since": "2026-04-14"}})
        # scraped_at is MYT (+08:00), so the date is Malaysia's even on a UTC runner.
        assert payload["scraped_at"].endswith("+08:00")
        assert payload["oer"]["in_app_since"] == payload["scraped_at"][:10]

    def test_the_same_month_keeps_its_date(self):
        payload = self._decide({"oer": {"year": 2026, "month": 4, "in_app_since": "2026-05-13"}})
        assert payload["oer"]["in_app_since"] == "2026-05-13"

    def test_the_first_snapshot_is_dated_today(self):
        payload = self._decide(None)
        assert payload["oer"]["in_app_since"] == payload["scraped_at"][:10]

    def test_an_unknown_date_stays_unknown_rather_than_guessed(self):
        assert self._decide({"oer": {"year": 2026, "month": 4}})["oer"]["in_app_since"] is None

    def test_september_2026_is_dated_from_the_data_history(self):
        # Its first data commit on main is 533bd08, 12 Oct 2026.
        september = {"year": 2026, "month": 9}
        assert oer_in_app_since(september, dict(september), "2026-10-18") == "2026-10-12"

    def test_a_carried_forward_oer_keeps_its_date(self):
        previous = {**TestKeepLastGoodData.PREVIOUS,
                    "oer": {**TestKeepLastGoodData.PREVIOUS["oer"], "in_app_since": "2026-05-13"}}
        payload = decide_payload(TestBuildPayload()._make_cpo(), None, False, None, previous)
        assert payload["oer"]["carried_forward"] is True
        assert payload["oer"]["in_app_since"] == "2026-05-13"


class TestTimeLimit:
    """K23: when MPOB doesn't answer, the run still finishes inside the job's 10 minutes."""

    def test_the_legacy_bepi_attempt_gets_a_short_timeout(self, monkeypatch):
        import run_scraper

        class Stop(Exception):
            pass

        seen = {}

        class FakeBEPI:
            def __init__(self, **kwargs):
                seen.update(kwargs)

            def scrape_all(self):
                return {"success": False}

        def stop():
            raise Stop

        monkeypatch.setattr(run_scraper, "MPOBScraper", FakeBEPI)
        monkeypatch.setattr(run_scraper, "MPOCDailyCPOScraper", stop)
        with pytest.raises(Stop):
            run_scraper.main()
        assert seen["timeout"] == run_scraper.LEGACY_BEPI_TIMEOUT
        assert run_scraper.LEGACY_BEPI_TIMEOUT <= 10


class TestMainKeepsLastSnapshot:
    def test_run_without_cpo_writes_nothing_and_fails(self, monkeypatch):
        import run_scraper
        from types import SimpleNamespace

        writes = []
        monkeypatch.setattr(run_scraper, "MPOBScraper",
                            lambda **kwargs: SimpleNamespace(scrape_all=lambda: {"success": False}))
        monkeypatch.setattr(run_scraper, "MPOCDailyCPOScraper", lambda: SimpleNamespace(scrape=lambda: None))
        monkeypatch.setattr(run_scraper, "MPOBOERScraper", lambda: SimpleNamespace(scrape=lambda: None))
        monkeypatch.setattr(run_scraper, "MPOBFFBScraper", lambda: SimpleNamespace(scrape=lambda: None))
        monkeypatch.setattr(run_scraper, "fetch_cpo_fallback", lambda: None)
        monkeypatch.setattr(run_scraper, "read_latest", lambda: TestKeepLastGoodData.PREVIOUS)
        monkeypatch.setattr(run_scraper, "write_price_data", lambda payload: writes.append(payload) or True)
        monkeypatch.setattr(run_scraper, "report_failure", lambda msg="": {})
        monkeypatch.setattr(run_scraper, "report_success", lambda: {})

        assert run_scraper.main() == 1
        assert writes == []  # latest.json is left as it was

    def test_a_run_publishes_mpobs_prices(self, monkeypatch):
        import run_scraper
        from types import SimpleNamespace

        writes = []
        maker = TestBuildPayload()
        monkeypatch.setattr(run_scraper, "MPOBScraper",
                            lambda **kwargs: SimpleNamespace(scrape_all=lambda: {"success": False}))
        monkeypatch.setattr(run_scraper, "MPOCDailyCPOScraper",
                            lambda: SimpleNamespace(scrape=lambda: SimpleNamespace(latest=maker._make_cpo())))
        monkeypatch.setattr(run_scraper, "MPOBOERScraper", lambda: SimpleNamespace(scrape=maker._make_oer))
        monkeypatch.setattr(run_scraper, "MPOBFFBScraper", lambda: SimpleNamespace(scrape=_make_ffb))
        monkeypatch.setattr(run_scraper, "read_latest", lambda: None)
        monkeypatch.setattr(run_scraper, "write_price_data", lambda payload: writes.append(payload) or True)
        monkeypatch.setattr(run_scraper, "report_failure", lambda msg="": {})
        monkeypatch.setattr(run_scraper, "report_success", lambda: {})

        assert run_scraper.main() == 0
        (payload,) = writes
        assert payload["formula_status"] == "OFFICIAL"
        assert payload["ffb"]["regions"][1]["price_1pct_oer"] == pytest.approx(48.20)
        assert payload["warnings"] == []
