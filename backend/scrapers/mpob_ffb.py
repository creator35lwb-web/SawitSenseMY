"""MPOB's daily FFB reference price by region (D22).

MPOB publishes its "MPOB Daily FFB Reference Price Summary by Region (Mill
Gate) (RM/1% OER)" as a PDF that needs no login, holding the month to date:

    https://price.mpob.gov.my/pdf/daily/ffb/<YYYY-MM-DD>

Each row is a day, with the price per 1% OER for North, South, Central,
East Coast, Sabah and Sarawak (Miri & Bintulu), or NT (no trade) or PH
(public holiday). This is the official benchmark SawitSense was built around:
Price/mt = MPOB Price_1% x graded OER. Until 23 Oct 2026 SawitSense showed
an estimate instead, believing these figures were behind a licensee login;
the estimate was 6-11% off in the Peninsula (K25, ADR-002).

The PDF is read with the standard library. Its text sits in a
Flate-compressed content stream as positioned strings, so the table is
rebuilt from their positions. Anything unexpected (a different title, month,
header or cell) rejects the whole document, rather than publishing a
misread price.

Author: SS (Claude Code), Oct 2026
"""

import logging
import re
import zlib
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from typing import Optional

import requests

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
FFB_PDF_URL = "https://price.mpob.gov.my/pdf/daily/ffb/{day}"
SOURCE = "MPOB Daily FFB Reference Price (mill gate)"
TITLE = "MPOB DAILY FFB REFERENCE PRICE SUMMARY BY REGION (MILL GATE) (RM/1% OER)"
DATE_HEADER = "Date / Tarikh"
# MPOB's columns, in its order, and the SawitSense region each one is.
COLUMNS = (
    ("North / Utara", "North"),
    ("South / Selatan", "South"),
    ("Central / Tengah", "Central"),
    ("East Coast / Timur", "East Coast"),
    ("Sabah", "Sabah"),
    ("Sarawak*", "Sarawak"),
)
NO_PRICE = ("NT", "PH")  # no trade, public holiday
# RM per 1% OER. Anything outside this can only be a misread.
PLAUSIBLE = (10.0, 200.0)
MONTHS = ("JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
          "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER")

DEFAULT_HEADERS = {
    "User-Agent": "SawitSense/1.0 (+https://github.com/creator35lwb-web/SawitSenseMY)",
    "Accept": "application/pdf",
}

_STREAM = re.compile(rb">>\s*stream\r?\n")
_TEXT = re.compile(
    r"BT\s+(-?[\d.]+)\s+(-?[\d.]+)\s+Td\s+/F\w+\s+[\d.]+\s+Tf\s+\[(.*?)\]\s*TJ\s+ET", re.S
)
_PRICE = re.compile(r"\d{1,3}\.\d{2}")
_LAST_UPDATE = re.compile(r"Last update\s*:\s*(\d{2})/(\d{2})/(\d{4})\s+(\d{1,2}):(\d{2})\s*([ap]m)", re.I)
_BACKSLASH = chr(92)
_ESCAPES = {"n": "\n", "r": "\r", "t": "\t", "b": "\b", "f": "\f"}


class FFBParseError(ValueError):
    """The document isn't MPOB's daily FFB summary as SawitSense knows it."""


@dataclass
class FFBDailyPrices:
    """The latest MPOB price per 1% OER for each region."""
    date_iso: str            # the latest trading day with prices
    prices: dict             # SawitSense region -> RM per 1% OER
    dates: dict              # SawitSense region -> the day of its price
    year: int
    month: int
    source_url: str
    last_update: Optional[str] = None   # when MPOB last updated the PDF (ISO, MYT)
    sarawak_note: Optional[str] = None  # MPOB's footnote, e.g. "Miri & Bintulu"
    source: str = SOURCE
    scraped_at: str = field(default_factory=lambda: datetime.now(MYT).isoformat())


def _content_streams(pdf: bytes):
    """The PDF's Flate-compressed streams, decoded; others are skipped."""
    for m in _STREAM.finditer(pdf):
        end = pdf.find(b"endstream", m.end())
        if end < 0:
            continue
        try:
            yield zlib.decompress(pdf[m.end():end]).decode("latin-1")
        except zlib.error:
            continue  # an image or another filter


def _literal_text(array: str) -> str:
    """The text of the literal strings in a TJ array, with PDF escapes undone."""
    out, depth, i = [], 0, 0
    while i < len(array):
        c = array[i]
        if depth == 0:
            depth = 1 if c == "(" else 0
            i += 1
            continue
        if c == _BACKSLASH and i + 1 < len(array):
            octal = re.match(r"[0-7]{1,3}", array[i + 1:])
            if octal:
                out.append(chr(int(octal.group(0), 8)))
                i += 1 + len(octal.group(0))
            else:
                out.append(_ESCAPES.get(array[i + 1], array[i + 1]))
                i += 2
            continue
        depth += {"(": 1, ")": -1}.get(c, 0)
        if depth > 0:
            out.append(c)
        i += 1
    return "".join(out)


def pdf_rows(pdf: bytes) -> list:
    """The document's text as rows of cells, top to bottom, left to right."""
    by_line = {}
    for content in _content_streams(pdf):
        for m in _TEXT.finditer(content):
            x, y = float(m.group(1)), float(m.group(2))
            by_line.setdefault(round(y, 1), []).append((x, _literal_text(m.group(3)).strip()))
    return [[text for _, text in sorted(cells)] for _, cells in sorted(by_line.items(), reverse=True)]


def _table(rows: list, year: int, month: int) -> list:
    """The table's day rows, after checking the title, month and header."""
    lines = [" ".join(row) for row in rows]
    if TITLE not in lines:
        raise FFBParseError("the title of MPOB's daily FFB summary is missing")
    if f"{MONTHS[month - 1]} {year}" not in lines:
        raise FFBParseError(f"the document isn't for {MONTHS[month - 1]} {year}")
    header = [DATE_HEADER, *(column for column, _ in COLUMNS)]
    if header not in rows:
        raise FFBParseError("the table's columns aren't the ones expected")
    table = []
    for row in rows[rows.index(header) + 1:]:
        if not row or not row[0].isdigit():
            break  # the notes under the table
        table.append(row)
    return table


def _check_cell(cell: str, day: int) -> Optional[float]:
    """A cell's price, or None for NT/PH; anything else is a misread."""
    if cell in NO_PRICE:
        return None
    if not _PRICE.fullmatch(cell):
        raise FFBParseError(f"an unexpected cell on day {day}")
    value = float(cell)
    if not PLAUSIBLE[0] <= value <= PLAUSIBLE[1]:
        raise FFBParseError(f"an implausible price on day {day}")
    return value


def _last_update(rows: list) -> Optional[str]:
    for row in rows:
        m = _LAST_UPDATE.search(" ".join(row))
        if m:
            d, mo, y, hh, mm, ampm = m.groups()
            hour = int(hh) % 12 + (12 if ampm.lower() == "pm" else 0)
            return datetime(int(y), int(mo), int(d), hour, int(mm), tzinfo=MYT).isoformat()
    return None


def _sarawak_note(rows: list) -> Optional[str]:
    """MPOB's footnote to its Sarawak column, on one short line."""
    for row in rows:
        text = " ".join(row)
        if text.startswith("* "):
            return " ".join(text[2:].split()).rstrip(".")[:60]
    return None


def parse_ffb_pdf(pdf: bytes, year: int, month: int, source_url: str) -> Optional[FFBDailyPrices]:
    """Each region's latest price in MPOB's summary for a month.

    None when no day of the month has prices yet. On a day that is a holiday
    in some regions only, those regions keep their earlier price and date.
    Raises FFBParseError when the document isn't the summary it should be.
    """
    if not pdf.startswith(b"%PDF"):
        raise FFBParseError("the answer isn't a PDF")
    rows = pdf_rows(pdf)
    prices, dates, last_day = {}, {}, 0
    for row in _table(rows, year, month):
        day = int(row[0])
        try:
            day_iso = date(year, month, day).isoformat()
        except ValueError:
            day_iso = None
        if len(row) != 1 + len(COLUMNS) or day <= last_day or day_iso is None:
            raise FFBParseError(f"an unexpected row for day {row[0]}")
        last_day = day
        for (_, region), cell in zip(COLUMNS, row[1:]):
            value = _check_cell(cell, day)
            if value is not None:
                prices[region] = value
                dates[region] = day_iso
    if not prices:
        return None
    if len(prices) < len(COLUMNS):
        raise FFBParseError("some regions have no price this month")
    return FFBDailyPrices(
        date_iso=max(dates.values()),
        prices=prices,
        dates=dates,
        year=year,
        month=month,
        source_url=source_url,
        last_update=_last_update(rows),
        sarawak_note=_sarawak_note(rows),
    )


class MPOBFFBScraper:
    """Reads MPOB's daily FFB summary for this month, or last month's early on the 1st."""

    def __init__(self, timeout: int = 30, max_retries: int = 2, connect_timeout: int = 10):
        self.timeout = timeout
        self.max_retries = max_retries
        self.connect_timeout = connect_timeout
        self.session = requests.Session()
        self.session.headers.update(DEFAULT_HEADERS)

    def fetch(self, day: date):
        """(url, PDF bytes) for the month holding `day`; bytes are b"" when
        MPOB has no such document, and None when the request failed."""
        url = FFB_PDF_URL.format(day=day.isoformat())
        for attempt in range(self.max_retries + 1):
            try:
                resp = self.session.get(url, timeout=(self.connect_timeout, self.timeout))
                if resp.status_code == 404:
                    return url, b""
                resp.raise_for_status()
                return url, resp.content
            except requests.RequestException:
                logger.warning(f"MPOB FFB fetch attempt {attempt + 1} failed", exc_info=True)
        logger.error("MPOB FFB: the daily price summary isn't answering")
        return url, None

    def scrape(self, today: Optional[date] = None) -> Optional[FFBDailyPrices]:
        today = today or datetime.now(MYT).date()
        last_month = today.replace(day=1) - timedelta(days=1)
        for day in (today, last_month):
            url, pdf = self.fetch(day)
            if pdf is None:
                return None  # the server is down; last month's is on it too (K23)
            if pdf:
                try:
                    prices = parse_ffb_pdf(pdf, day.year, day.month, url)
                except FFBParseError as e:
                    # Never the document's text, which could forge log lines.
                    logger.error(f"MPOB FFB: {e} ({len(pdf)} bytes from {url})")
                    return None
                if prices:
                    logger.info(f"MPOB FFB {prices.date_iso}: " + ", ".join(
                        f"{region} {price:.2f}" for region, price in prices.prices.items()))
                    return prices
            logger.info(f"MPOB FFB: no prices yet for {day:%B %Y}")
        logger.error("MPOB FFB: no prices this month or last")
        return None
