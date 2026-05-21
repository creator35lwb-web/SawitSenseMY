"""Tests for the MPOC daily CPO collector.

Author: QQ (Perplexity) \u2014 recovery patch (May 2026)
"""

from datetime import datetime, timezone, timedelta
from unittest.mock import MagicMock, patch

import pytest

from scrapers.mpoc_cpo import (
    MPOCDailyCPOScraper,
    parse_mpoc_date,
    parse_price_number,
    _find_settlement_table,
)
from bs4 import BeautifulSoup


MYT = timezone(timedelta(hours=8))


class TestParseMpocDate:
    def test_basic_short_year(self):
        assert parse_mpoc_date("20 May 26", today=datetime(2026, 5, 21, tzinfo=MYT)) == "2026-05-20"

    def test_zero_padded_day(self):
        assert parse_mpoc_date("07 May 26", today=datetime(2026, 5, 21, tzinfo=MYT)) == "2026-05-07"

    def test_full_year(self):
        assert parse_mpoc_date("15 Jan 2025", today=datetime(2026, 1, 1, tzinfo=MYT)) == "2025-01-15"

    def test_sept_variant(self):
        assert parse_mpoc_date("01 Sept 25", today=datetime(2026, 1, 1, tzinfo=MYT)) == "2025-09-01"

    def test_implausible_future_year_rejected(self):
        # year 2099 with today=2026 must reject
        assert parse_mpoc_date("01 Jan 99", today=datetime(2026, 1, 1, tzinfo=MYT)) is None or \
               parse_mpoc_date("01 Jan 2099", today=datetime(2026, 1, 1, tzinfo=MYT)) is None

    def test_garbage(self):
        assert parse_mpoc_date("not a date") is None
        assert parse_mpoc_date("") is None
        assert parse_mpoc_date(None) is None


class TestParsePriceNumber:
    def test_plain(self):
        assert parse_price_number("4541") == pytest.approx(4541.0)

    def test_comma_thousands(self):
        assert parse_price_number("4,541") == pytest.approx(4541.0)

    def test_nt(self):
        assert parse_price_number("NT") is None

    def test_dash(self):
        assert parse_price_number("-") is None

    def test_empty(self):
        assert parse_price_number("") is None


class TestFindSettlementTable:
    def test_picks_correct_table(self):
        html = """
        <html><body>
          <table><tr><th>Foo</th><th>Bar</th></tr><tr><td>1</td><td>2</td></tr></table>
          <table><tr><th>Pricing Date</th><th>Settlement Price RM</th></tr>
                 <tr><td>20 May 26</td><td>4,583</td></tr></table>
        </body></html>
        """
        soup = BeautifulSoup(html, "html.parser")
        t = _find_settlement_table(soup)
        assert t is not None
        assert "Settlement" in t.get_text()

    def test_returns_none_when_absent(self):
        soup = BeautifulSoup("<html><body><table><tr><td>x</td></tr></table></body></html>", "html.parser")
        assert _find_settlement_table(soup) is None


class TestScraperFlow:
    SAMPLE_HTML = """
      <html><body>
        <h2>Daily Palm Oil Prices</h2>
        <table>
          <tr><th>Pricing Date</th><th>Settlement Price RM</th></tr>
          <tr><td>7 May 26</td><td>4,541</td></tr>
          <tr><td>8 May 26</td><td>4,505</td></tr>
          <tr><td>20 May 26</td><td>4,583</td></tr>
        </table>
      </body></html>
    """

    def _mock_response(self, text, status=200):
        m = MagicMock()
        m.status_code = status
        m.text = text
        m.raise_for_status = MagicMock()
        return m

    def test_happy_path(self):
        scraper = MPOCDailyCPOScraper()
        with patch.object(scraper.session, "get", return_value=self._mock_response(self.SAMPLE_HTML)):
            series = scraper.scrape()
        assert series is not None
        assert len(series.observations) == 3
        assert series.latest.date_iso == "2026-05-20"
        assert series.latest.price_myr_per_tonne == pytest.approx(4583.0)

    def test_no_table_returns_none(self):
        scraper = MPOCDailyCPOScraper()
        with patch.object(scraper.session, "get", return_value=self._mock_response("<html><body>no tables</body></html>")):
            assert scraper.scrape() is None

    def test_network_failure_returns_none(self):
        import requests
        scraper = MPOCDailyCPOScraper(max_retries=1)
        with patch.object(scraper.session, "get", side_effect=requests.ConnectionError("nope")):
            assert scraper.scrape() is None
