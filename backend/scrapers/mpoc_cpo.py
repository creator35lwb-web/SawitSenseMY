"""MPOC Daily CPO Price Collector for SawitSense.

Pulls daily CPO settlement price (RM/tonne) from the Malaysian Palm Oil
Council (MPOC) public daily prices page. This is the public fallback after
MPOB BEPI moved its FFB Reference Price tables behind a licensee login
(see ADR-001 in docs/).

Source URL: https://mpoc.org.my/daily-palm-oil-prices/
Data shape: HTML table with columns: "Pricing Date" | "Settlement Price RM"
Reliability: Static HTML, no JS, no auth — high.

Author: QQ (Perplexity), May 2026 — recovery patch under Alton's authority
(part of the YSenseAI ecosystem).
Original SawitSense data layer authored by QQ (Qoder CSO).
Patch: SS (Claude Code), Oct 2026 — a page that comes back without the price
table is fetched again, and a final miss logs what the page was (K22).
"""

from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone, timedelta
from typing import Optional

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
MPOC_URL = "https://mpoc.org.my/daily-palm-oil-prices/"

# Browser-like UA — MPOC's CloudFront sometimes blocks generic clients.
DEFAULT_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 "
        "SawitSense/1.0 (+https://github.com/creator35lwb-web/SawitSenseMY)"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}


@dataclass
class MPOCDailyCPO:
    """A single daily CPO settlement observation from MPOC."""

    date_iso: str  # ISO date (YYYY-MM-DD)
    date_raw: str  # As shown on MPOC, e.g. "20 May 26"
    price_myr_per_tonne: float
    source: str = "MPOC Daily Palm Oil Prices"
    source_url: str = MPOC_URL
    scraped_at: str = ""

    def __post_init__(self) -> None:
        if not self.scraped_at:
            self.scraped_at = datetime.now(MYT).isoformat()


@dataclass
class MPOCDailyCPOSeries:
    """The rolling window of recent daily CPO observations MPOC publishes."""

    latest: Optional[MPOCDailyCPO] = None
    observations: list = field(default_factory=list)
    source: str = "MPOC Daily Palm Oil Prices"
    source_url: str = MPOC_URL
    scraped_at: str = ""

    def __post_init__(self) -> None:
        if not self.scraped_at:
            self.scraped_at = datetime.now(MYT).isoformat()


_MONTH_MAP = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "sept": 9, "oct": 10, "nov": 11, "dec": 12,
}


def parse_mpoc_date(
    raw: Optional[str], today: Optional[datetime] = None
) -> Optional[str]:
    """Parse MPOC short date format ('20 May 26') -> ISO 'YYYY-MM-DD'.

    Returns None if the string is not parseable, empty, or None. Two-digit
    years are treated as 2000+YY, with a sanity guard against years more
    than 1 year ahead of 'today' (defensive against typos on MPOC's page).
    """
    if not raw:
        return None
    cleaned = raw.strip()
    m = re.match(r"^\s*(\d{1,2})\s+([A-Za-z]{3,5})\s+(\d{2,4})\s*$", cleaned)
    if not m:
        return None
    day = int(m.group(1))
    mon_token = m.group(2).lower()
    mon = _MONTH_MAP.get(mon_token[:3])
    if not mon:
        return None
    yr = int(m.group(3))
    if yr < 100:
        yr += 2000
    today = today or datetime.now(MYT)
    if yr > today.year + 1:  # implausible future date
        logger.warning(f"Implausible MPOC date year {yr} from '{raw}'")
        return None
    try:
        return datetime(yr, mon, day).strftime("%Y-%m-%d")
    except ValueError:
        return None


def parse_price_number(text: Optional[str]) -> Optional[float]:
    """Parse MPOC price cell (e.g. '4,541' or '4541' or 'NT') -> float."""
    if not text:
        return None
    cleaned = text.strip().upper()
    if cleaned in ("", "-", "NT", "N/T", "N/A", "TBD"):
        return None
    cleaned = re.sub(r"[^0-9.,]", "", cleaned).replace(",", "")
    if not cleaned:
        return None
    try:
        return float(cleaned)
    except ValueError:
        return None


def _find_settlement_table(soup: BeautifulSoup):
    """Locate the 'Pricing Date / Settlement Price RM' table on the MPOC page.

    MPOC's page contains several tables. We look for the one whose header row
    mentions both 'Pricing Date' and 'Settlement Price' (case-insensitive).
    """
    for table in soup.find_all("table"):
        head_text = table.get_text(" ", strip=True).lower()
        if "pricing date" in head_text and "settlement" in head_text:
            return table
    return None


# Signs of what MPOC served instead of its price page, for the log (K22).
_PAGE_HINTS = (
    ("cloudfront", "a CloudFront error page"),
    ("captcha", "a bot check"),
    # MPOC's own check, served to SS's machine on 23 Oct 2026: "Please wait
    # while your request is being verified".
    ("request is being verified", "a bot check"),
    ("maintenance", "a maintenance notice"),
)


def _describe_page(soup: BeautifulSoup, html: str) -> str:
    """Describe a page that had no price table, for the log.

    Its size, how many tables it has (none suggests an error or block page;
    some suggests MPOC changed its layout), and any sign of what it was. The
    page's own text is never repeated, so the page can't write into the log.
    """
    lower = html.lower()
    hints = list(dict.fromkeys(label for marker, label in _PAGE_HINTS if marker in lower))
    described = f"{len(html)} bytes, {len(soup.find_all('table'))} tables"
    return described + (f", looks like {' and '.join(hints)}" if hints else "")


class MPOCDailyCPOScraper:
    """Public daily CPO settlement scraper (MPOC)."""

    def __init__(self, timeout: int = 30, max_retries: int = 2, retry_pause: float = 30):
        self.timeout = timeout
        self.max_retries = max_retries
        # Seconds to wait before fetching again a page that came back without
        # the price table (K22).
        self.retry_pause = retry_pause
        self.session = requests.Session()
        self.session.headers.update(DEFAULT_HEADERS)

    def fetch_html(self) -> Optional[str]:
        for attempt in range(self.max_retries + 1):
            try:
                resp = self.session.get(MPOC_URL, timeout=self.timeout)
                resp.raise_for_status()
                return resp.text
            except requests.RequestException:
                logger.warning(
                    f"MPOC fetch attempt {attempt + 1} failed", exc_info=True
                )
        logger.error(f"MPOC fetch failed after {self.max_retries + 1} attempts")
        return None

    def fetch_settlement_table(self):
        """The settlement-price table from MPOC's page, or None.

        On 22 Oct 2026 MPOC answered once with a page that had no price table,
        and the next fetch was fine (K22). Such a page is fetched again after a
        pause; if the table is still missing, the log says what the page was.
        """
        for attempt in range(self.max_retries + 1):
            html = self.fetch_html()
            if not html:
                return None
            soup = BeautifulSoup(html, "html.parser")
            table = _find_settlement_table(soup)
            if table:
                return table
            if attempt < self.max_retries:
                logger.warning(
                    f"MPOC: no settlement-price table on the page (attempt {attempt + 1}); fetching again"
                )
                time.sleep(self.retry_pause)
        logger.error(f"MPOC: settlement-price table not found on page ({_describe_page(soup, html)})")
        return None

    def scrape(self) -> Optional[MPOCDailyCPOSeries]:
        """Return the full recent series + the latest non-null observation."""
        table = self.fetch_settlement_table()
        if not table:
            return None

        rows = table.find_all("tr")
        if len(rows) < 2:
            logger.error("MPOC: settlement table has no data rows")
            return None

        series = MPOCDailyCPOSeries()
        for row in rows[1:]:  # skip header
            cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
            if len(cells) < 2:
                continue
            iso_date = parse_mpoc_date(cells[0])
            price = parse_price_number(cells[1])
            if not iso_date or price is None:
                continue
            obs = MPOCDailyCPO(
                date_iso=iso_date,
                date_raw=cells[0],
                price_myr_per_tonne=price,
            )
            series.observations.append(obs)

        if not series.observations:
            logger.error("MPOC: parsed zero observations from settlement table")
            return None

        # Latest = highest date_iso (MPOC may not always be sorted)
        series.observations.sort(key=lambda o: o.date_iso)
        series.latest = series.observations[-1]
        logger.info(
            f"MPOC: scraped {len(series.observations)} observations, "
            f"latest = {series.latest.date_iso} @ RM {series.latest.price_myr_per_tonne}"
        )
        return series
