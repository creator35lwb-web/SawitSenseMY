"""MPOB BEPI Scraper for SawitSense.

Historically scraped CPO spot price and FFB Reference Price (6 regions) from
MPOB's BEPI portal at bepi.mpob.gov.my.

!! DATA-SOURCE NOTICE (recovery patch, May 2026)
   MPOB restructured the BEPI portal. The daily FFB Reference Price tables
   that this scraper depended on are now login-gated:
     'PRIVILEGED ACCESS ONLY TO MPOB LICENSEES'
   Both legacy URLs return HTTP 404 to anonymous clients. As a result this
   module's network methods will fail gracefully and the pipeline now relies
   on two public collectors in this same package:
     - scrapers.mpoc_cpo  (daily CPO settlement RM/tonne)
     - scrapers.mpob_oer  (monthly OER % per state, official MPOB API)
   See docs/ADR-001-mpob-data-source-change.md for the full record.

   The pure-math helpers in this file (parse_price, calculate_fair_price,
   get_price_verdict, oer_sensitivity) are SawitSense's core formula and are
   preserved unchanged. They continue to be the single source of truth for
   the Fair Price verdict.

Original author: QQ (Qoder CSO)
Recovery patch:  QQ (Perplexity) — on behalf of YSenseAI / CIO XV (May 2026)
"""

import re
import logging
from datetime import datetime, timezone, timedelta
from dataclasses import dataclass, field, asdict
from typing import Optional

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))

# DEPRECATED — kept for archival reference and for tests that may pin them.
# These now return HTTP 404 to anonymous traffic; do not use in production.
MPOB_CPO_URL = "https://bepi.mpob.gov.my/index.php/en/statistics/price/daily.html"
MPOB_FFB_URL = "https://bepi.mpob.gov.my/index.php/en/statistics/price/ffb.html"

REGIONS = ["North", "South", "Central", "East Coast", "Sabah", "Sarawak"]


@dataclass
class CPOPrice:
    """CPO spot price data."""
    date: str
    price_myr_per_tonne: float
    source: str = "MPOB BEPI"
    scraped_at: str = ""

    def __post_init__(self):
        if not self.scraped_at:
            self.scraped_at = datetime.now(MYT).isoformat()


@dataclass
class FFBRegionalPrice:
    """FFB Reference Price at 1% OER for a specific region."""
    region: str
    date: str
    price_1pct_oer: float
    source: str = "MPOB BEPI"


@dataclass
class FFBPriceData:
    """Complete FFB price data across all regions."""
    date: str
    regions: list = field(default_factory=list)
    cpo_price: Optional[float] = None
    source: str = "MPOB BEPI"
    scraped_at: str = ""

    def __post_init__(self):
        if not self.scraped_at:
            self.scraped_at = datetime.now(MYT).isoformat()


def parse_price(text: str) -> Optional[float]:
    """Parse price string from MPOB HTML.

    Handles formats: '4,600.00', 'RM 4600', '42.77', 'NT', '-', empty.
    """
    if not text or not text.strip():
        return None

    cleaned = text.strip().upper()

    if cleaned in ("NT", "N/T", "-", "N/A", ""):
        return None

    cleaned = re.sub(r"[^\d.,]", "", cleaned)
    cleaned = cleaned.replace(",", "")

    try:
        return float(cleaned)
    except (ValueError, TypeError):
        logger.warning(f"Could not parse price: '{text}'")
        return None


def calculate_fair_price(price_1pct_oer: float, graded_oer: float) -> float:
    """Calculate fair FFB price using confirmed MPOB formula.

    Formula: Price/mt = Price_1% x Graded_OER%
    Confirmed from real Sdn Bhd payment voucher (PV-85935).

    Args:
        price_1pct_oer: MPOB rate per 1% OER (RM)
        graded_oer: Graded OER percentage (e.g., 18.0 for 18%)

    Returns:
        Fair price in RM per tonne of FFB
    """
    return round(price_1pct_oer * graded_oer, 2)


def get_price_verdict(paid_price: float, benchmark_price: float) -> dict:
    """Compare dealer price against MPOB benchmark.

    Returns verdict: GREEN (within 5%), AMBER (5-15% below), RED (>15% below).
    """
    if benchmark_price <= 0:
        return {"verdict": "UNKNOWN", "gap_rm": 0, "gap_pct": 0}

    gap_rm = round(paid_price - benchmark_price, 2)
    gap_pct = round((gap_rm / benchmark_price) * 100, 2)

    if gap_pct >= -5:
        verdict = "GREEN"
    elif gap_pct >= -15:
        verdict = "AMBER"
    else:
        verdict = "RED"

    return {
        "verdict": verdict,
        "gap_rm": gap_rm,
        "gap_pct": gap_pct,
        "benchmark_price": benchmark_price,
        "paid_price": paid_price,
    }


def oer_sensitivity(price_1pct_oer: float, oer_range: tuple = (16, 23)) -> list:
    """Show how price changes with each 1% OER.

    Empowers smallholders to understand: 'Each 1% OER = RM XX/tonne'.
    """
    result = []
    for oer in range(oer_range[0], oer_range[1] + 1):
        result.append({
            "oer_pct": oer,
            "price_per_tonne": calculate_fair_price(price_1pct_oer, oer),
        })
    return result


class MPOBScraper:
    """Scraper for MPOB BEPI portal."""

    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "SawitSense/1.0 (Open Source CPO Tracker; +https://github.com/creator35lwb-web/SawitSenseMY)",
            "Accept": "text/html,application/xhtml+xml",
        })

    def scrape_cpo_price(self) -> Optional[CPOPrice]:
        """Legacy CPO scraper — kept for compatibility, now expected to fail.

        Returns None and logs a clear deprecation message. Callers should use
        scrapers.mpoc_cpo.MPOCDailyCPOScraper instead.
        """
        try:
            resp = self.session.get(MPOB_CPO_URL, timeout=self.timeout)
            if resp.status_code == 404:
                logger.info(
                    "MPOB BEPI CPO URL returns 404 — endpoint deprecated. "
                    "Use scrapers.mpoc_cpo for daily CPO settlement instead."
                )
                return None
            resp.raise_for_status()

            soup = BeautifulSoup(resp.text, "html.parser")
            table = soup.find("table")

            if not table:
                logger.error("No table found on CPO price page")
                return None

            rows = table.find_all("tr")
            if len(rows) < 2:
                logger.error("Table has insufficient rows")
                return None

            last_row = rows[-1]
            cells = last_row.find_all(["td", "th"])

            if len(cells) < 2:
                logger.error("Last row has insufficient cells")
                return None

            date_text = cells[0].get_text(strip=True)
            price_text = cells[1].get_text(strip=True)
            price = parse_price(price_text)

            if price is None:
                logger.warning(f"Could not parse CPO price from: '{price_text}'")
                return None

            return CPOPrice(date=date_text, price_myr_per_tonne=price)

        except requests.RequestException:
            logger.exception("Failed to scrape CPO price")
            return None

    def scrape_ffb_prices(self) -> Optional[FFBPriceData]:
        """Legacy FFB Reference Price scraper — now login-gated upstream.

        Returns None and logs a clear deprecation message. The authoritative
        daily FFB Reference Price (RM per 1% OER, 6 regions) now requires an
        MPOB licensee account; see ADR-001.
        """
        try:
            resp = self.session.get(MPOB_FFB_URL, timeout=self.timeout)
            if resp.status_code == 404:
                logger.info(
                    "MPOB BEPI FFB URL returns 404 — endpoint moved behind "
                    "licensee login. Indicative regional benchmarks now come "
                    "from scrapers.mpob_oer (monthly OER) combined with "
                    "scrapers.mpoc_cpo (daily CPO settlement)."
                )
                return None
            resp.raise_for_status()

            soup = BeautifulSoup(resp.text, "html.parser")
            table = soup.find("table")

            if not table:
                logger.error("No table found on FFB price page")
                return None

            rows = table.find_all("tr")
            if len(rows) < 2:
                logger.error("Table has insufficient rows")
                return None

            last_row = rows[-1]
            cells = last_row.find_all(["td", "th"])

            if len(cells) < 7:
                logger.error(f"Expected 7+ cells (date + 6 regions), got {len(cells)}")
                return None

            date_text = cells[0].get_text(strip=True)
            ffb_data = FFBPriceData(date=date_text)

            for i, region in enumerate(REGIONS):
                if i + 1 < len(cells):
                    price = parse_price(cells[i + 1].get_text(strip=True))
                    if price is not None:
                        ffb_data.regions.append(
                            FFBRegionalPrice(
                                region=region,
                                date=date_text,
                                price_1pct_oer=price,
                            )
                        )

            if not ffb_data.regions:
                logger.warning("No regional prices parsed from FFB table")
                return None

            return ffb_data

        except requests.RequestException:
            logger.exception("Failed to scrape FFB prices")
            return None

    def scrape_all(self) -> dict:
        """Run full scrape: CPO + FFB prices."""
        result = {
            "cpo": None,
            "ffb": None,
            "scraped_at": datetime.now(MYT).isoformat(),
            "success": False,
        }

        cpo = self.scrape_cpo_price()
        if cpo:
            result["cpo"] = asdict(cpo)

        ffb = self.scrape_ffb_prices()
        if ffb:
            if cpo:
                ffb.cpo_price = cpo.price_myr_per_tonne
            result["ffb"] = asdict(ffb)

        result["success"] = cpo is not None or ffb is not None
        return result
