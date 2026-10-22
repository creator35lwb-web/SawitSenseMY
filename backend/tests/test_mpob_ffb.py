"""Tests for reading MPOB's daily FFB reference price summary (D22).

The PDFs are built here in the layout MPOB's server produces (positioned
text in a Flate-compressed stream), so the tests never contact MPOB and the
repo holds no copy of MPOB's document.

Author: SS (Claude Code), Oct 2026
"""

import zlib
from datetime import date
from unittest.mock import MagicMock, patch

import pytest
import requests

from scrapers.mpob_ffb import (
    DATE_HEADER,
    TITLE,
    FFBParseError,
    MPOBFFBScraper,
    parse_ffb_pdf,
    pdf_rows,
)

HEADER = [DATE_HEADER, "North / Utara", "South / Selatan", "Central / Tengah",
          "East Coast / Timur", "Sabah", "Sarawak*"]
# MPOB's figures for 1-2 and 19-22 October 2026, with a weekend between.
OCTOBER = [
    ["1", "47.25", "47.49", "47.45", "47.33", "41.99", "42.61"],
    ["2", "46.31", "46.80", "46.57", "46.50", "41.26", "41.88"],
    ["3", "NT", "NT", "NT", "NT", "NT", "NT"],
    ["4", "PH", "PH", "PH", "PH", "PH", "PH"],
    ["21", "47.75", "48.12", "48.05", "48.00", "43.00", "43.42"],
    ["22", "47.82", "48.20", "48.12", "48.08", "43.06", "43.49"],
]
URL = "https://price.mpob.gov.my/pdf/daily/ffb/2026-10-22"


def _escape(text: str) -> str:
    backslash = chr(92)
    return text.replace(backslash, backslash * 2).replace("(", backslash + "(").replace(")", backslash + ")")


def _pdf(table=OCTOBER, title=TITLE, month="OCTOBER 2026", header=HEADER,
         notes=("Note :", "NT - No Trade / Tiada Urusan", "* Miri & Bintulu.",
                "Last update : 22/10/2026 12:00 pm")) -> bytes:
    """A PDF laid out like MPOB's: one positioned string per cell."""
    rows = [["LEMBAGA MINYAK SAWIT MALAYSIA"], [title], [month], header, *table, *([n] for n in notes)]
    ops, y = [], 790.0
    for row in rows:
        # Cells are written right to left, as a layout engine may: the reader
        # must use their positions, not their order in the stream.
        for col in reversed(range(len(row))):
            ops.append(f"BT {34.0 + 75.2 * col:.3f} {y:.3f} Td /F2 6.0 Tf  [({_escape(row[col])})] TJ ET")
        y -= 11.9
    stream = zlib.compress("\n".join(ops).encode("latin-1"))
    return (b"%PDF-1.7\n1 0 obj\n<< /Length " + str(len(stream)).encode() + b" /Filter /FlateDecode >>\nstream\n"
            + stream + b"\nendstream\nendobj\n%%EOF\n")


class TestReadingThePdf:
    def test_rows_come_back_in_reading_order(self):
        rows = pdf_rows(_pdf())
        assert rows[1] == [TITLE]
        assert rows[3] == HEADER
        assert rows[4] == OCTOBER[0]

    def test_escaped_brackets_are_read_as_text(self):
        rows = pdf_rows(_pdf(notes=("(Ministry of Plantation and Commodities)",)))
        assert rows[-1] == ["(Ministry of Plantation and Commodities)"]

    def test_the_latest_priced_day_is_used(self):
        prices = parse_ffb_pdf(_pdf(), 2026, 10, URL)
        assert prices.date_iso == "2026-10-22"
        assert prices.prices == {"North": 47.82, "South": 48.20, "Central": 48.12,
                                 "East Coast": 48.08, "Sabah": 43.06, "Sarawak": 43.49}
        assert set(prices.dates.values()) == {"2026-10-22"}
        assert prices.source_url == URL

    def test_mpobs_update_time_and_sarawak_note_are_kept(self):
        prices = parse_ffb_pdf(_pdf(), 2026, 10, URL)
        assert prices.last_update == "2026-10-22T12:00:00+08:00"
        assert prices.sarawak_note == "Miri & Bintulu"

    def test_a_holiday_in_some_regions_keeps_their_earlier_price(self):
        # A state holiday: Sabah and Sarawak have no trade on the 22nd.
        table = OCTOBER[:5] + [["22", "47.82", "48.20", "48.12", "48.08", "PH", "PH"]]
        prices = parse_ffb_pdf(_pdf(table=table), 2026, 10, URL)
        assert prices.date_iso == "2026-10-22"
        assert prices.prices["North"] == pytest.approx(47.82)
        assert prices.prices["Sabah"] == pytest.approx(43.00)
        assert prices.dates["Sabah"] == "2026-10-21"
        assert prices.dates["North"] == "2026-10-22"

    def test_a_month_with_no_prices_yet_gives_none(self):
        table = [["1", "PH", "PH", "PH", "PH", "PH", "PH"]]
        assert parse_ffb_pdf(_pdf(table=table, month="NOVEMBER 2026"), 2026, 11, URL) is None


class TestAnythingUnexpectedIsRejected:
    """A misread price is worse than none: the last good prices stay up (K7)."""

    def test_not_a_pdf(self):
        with pytest.raises(FFBParseError, match="isn't a PDF"):
            parse_ffb_pdf(b"<html>Please log in</html>", 2026, 10, URL)

    def test_another_document(self):
        with pytest.raises(FFBParseError, match="title"):
            parse_ffb_pdf(_pdf(title="MPOB DAILY CPO PRICES"), 2026, 10, URL)

    def test_another_month(self):
        with pytest.raises(FFBParseError, match="SEPTEMBER 2026"):
            parse_ffb_pdf(_pdf(), 2026, 9, URL)

    def test_columns_in_another_order(self):
        header = [HEADER[0], HEADER[2], HEADER[1], *HEADER[3:]]
        with pytest.raises(FFBParseError, match="columns"):
            parse_ffb_pdf(_pdf(header=header), 2026, 10, URL)

    @pytest.mark.parametrize("cell", ["47.8", "4782", "-", "47.82*", ""])
    def test_a_cell_that_is_not_a_price(self, cell):
        table = OCTOBER[:5] + [["22", cell, "48.20", "48.12", "48.08", "43.06", "43.49"]]
        with pytest.raises(FFBParseError):
            parse_ffb_pdf(_pdf(table=table), 2026, 10, URL)

    def test_an_implausible_price(self):
        table = OCTOBER[:5] + [["22", "478.20", "48.20", "48.12", "48.08", "43.06", "43.49"]]
        with pytest.raises(FFBParseError, match="implausible"):
            parse_ffb_pdf(_pdf(table=table), 2026, 10, URL)

    def test_a_missing_cell(self):
        table = OCTOBER[:5] + [["22", "47.82", "48.20", "48.12", "48.08", "43.06"]]
        with pytest.raises(FFBParseError, match="day 22"):
            parse_ffb_pdf(_pdf(table=table), 2026, 10, URL)

    @pytest.mark.parametrize("day", ["21", "31"])
    def test_days_out_of_order_or_not_in_the_month(self, day):
        table = OCTOBER[:5] + [[day, "47.82", "48.20", "48.12", "48.08", "43.06", "43.49"]]
        month = "NOVEMBER 2026" if day == "31" else "OCTOBER 2026"
        with pytest.raises(FFBParseError, match="unexpected row"):
            parse_ffb_pdf(_pdf(table=table, month=month), 2026, 11 if day == "31" else 10, URL)

    def test_a_region_without_any_price_this_month(self):
        table = [["2", "46.31", "46.80", "46.57", "46.50", "41.26", "PH"]]
        with pytest.raises(FFBParseError, match="some regions"):
            parse_ffb_pdf(_pdf(table=table), 2026, 10, URL)


def _response(status=200, content=b""):
    resp = MagicMock()
    resp.status_code = status
    resp.content = content
    resp.raise_for_status.side_effect = (
        requests.HTTPError(f"{status}") if status >= 400 else None)
    return resp


class TestScraper:
    def test_reads_this_months_summary(self):
        scraper = MPOBFFBScraper()
        with patch.object(scraper.session, "get", return_value=_response(content=_pdf())) as get:
            prices = scraper.scrape(today=date(2026, 10, 23))
        assert prices.date_iso == "2026-10-22"
        (url,), kwargs = get.call_args
        assert url == "https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23"
        assert kwargs["timeout"] == (10, 30)

    def test_early_in_a_month_last_months_prices_are_used(self):
        empty_november = _pdf(table=[["1", "PH", "PH", "PH", "PH", "PH", "PH"]], month="NOVEMBER 2026")
        scraper = MPOBFFBScraper()
        answers = [_response(content=empty_november), _response(content=_pdf())]
        with patch.object(scraper.session, "get", side_effect=answers) as get:
            prices = scraper.scrape(today=date(2026, 11, 1))
        assert prices.date_iso == "2026-10-22"
        assert get.call_args_list[1].args[0] == "https://price.mpob.gov.my/pdf/daily/ffb/2026-10-31"

    def test_a_month_mpob_has_not_started_falls_back_too(self):
        scraper = MPOBFFBScraper()
        with patch.object(scraper.session, "get", side_effect=[_response(404), _response(content=_pdf())]):
            assert scraper.scrape(today=date(2026, 11, 1)).date_iso == "2026-10-22"

    def test_a_server_that_does_not_answer_is_not_asked_again_for_last_month(self):
        scraper = MPOBFFBScraper(max_retries=2)
        with patch.object(scraper.session, "get", side_effect=requests.ConnectTimeout("no answer")) as get:
            assert scraper.scrape(today=date(2026, 11, 1)) is None
        assert get.call_count == 3  # this month only (K23)

    def test_a_login_page_is_refused_and_its_text_never_logged(self, caplog):
        page = b"<html><title>Sistem eReg Bepi</title>Login" + chr(10).encode() + b"ERROR forged</html>"
        scraper = MPOBFFBScraper()
        with patch.object(scraper.session, "get", return_value=_response(content=page)):
            assert scraper.scrape(today=date(2026, 10, 23)) is None
        errors = [r.getMessage() for r in caplog.records if r.levelname == "ERROR"]
        assert errors == [f"MPOB FFB: the answer isn't a PDF ({len(page)} bytes from "
                          "https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23)"]
