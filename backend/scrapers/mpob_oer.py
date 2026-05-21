"""MPOB Prestasi Sawit OER Collector for SawitSense.

Pulls monthly OER (Oil Extraction Rate) performance from MPOB's public
Prestasi Sawit portal. This is the official MPOB OER dataset, the same
denominator-of-fairness that anchors SawitSense's smallholder verdict.

Source URL: https://prestasisawit.mpob.gov.my/api/oer
Params:     ?year=YYYY&month=MM  (MM is zero-padded, e.g. '04')
Reliability: Official MPOB JSON API, no auth — high.

Mapping of state codes to SawitSense regional buckets is provided so that
downstream code can fold per-state OER into the 6-region grid that the
README's Fair Price calculator expects (North / South / Central / East
Coast / Sabah / Sarawak).

Author: QQ (Perplexity) — recovery patch authored on behalf of YSenseAI / CIO XV.
Original SawitSense data layer authored by QQ (Qoder CSO).
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone, timedelta
from typing import Optional

import requests

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
OER_API_URL = "https://prestasisawit.mpob.gov.my/api/oer"

# Region labels — must match SawitSense's 6-region grid in scrapers.mpob_bepi.REGIONS
# and the frontend Flutter PriceData model.
REGION_NORTH = "North"
REGION_SOUTH = "South"
REGION_CENTRAL = "Central"
REGION_EAST_COAST = "East Coast"
REGION_SABAH = "Sabah"
REGION_SARAWAK = "Sarawak"

# MPOB state code -> (state name, SawitSense region)
# Region mapping follows the README's 6-region grid; cross-checked against
# MPOB Peninsular sub-region conventions used in their FFB Reference Price.
STATE_REGION_MAP = {
    "01": ("Johor",            REGION_SOUTH),
    "02": ("Kedah",            REGION_NORTH),
    "03": ("Kelantan",         REGION_EAST_COAST),
    "04": ("Melaka",           REGION_SOUTH),
    "05": ("Negeri Sembilan",  REGION_SOUTH),
    "06": ("Pahang",           REGION_EAST_COAST),
    "07": ("Perak",            REGION_NORTH),
    "08": ("Perlis",           REGION_NORTH),
    "09": ("Pulau Pinang",     REGION_NORTH),
    "10": ("Selangor",         REGION_CENTRAL),
    "11": ("Terengganu",       REGION_EAST_COAST),
    "12": ("Sabah",            REGION_SABAH),
    "13": ("Sarawak",          REGION_SARAWAK),
}

DEFAULT_HEADERS = {
    "User-Agent": (
        "SawitSense/1.0 "
        "(+https://github.com/creator35lwb-web/SawitSenseMY)"
    ),
    "Accept": "application/json, text/plain, */*",
    "X-Requested-With": "XMLHttpRequest",
    "Referer": "https://prestasisawit.mpob.gov.my/en/oer",
}


@dataclass
class StateOER:
    """Per-state monthly OER snapshot."""

    state_code: str
    state_name: str
    region: str
    year: str
    month: str  # zero-padded "01".."12"
    oer_cpo: float
    oer_cpko: float
    cpo_proc_tonnes: float
    ffb_proc_tonnes: float


@dataclass
class OERSnapshot:
    """Full monthly OER snapshot (national + per-state)."""

    year: int
    month: int
    oer_malaysia: float
    oer_peninsular: float
    oer_sabah: float
    oer_sarawak: float
    mill_count: int
    states: list = field(default_factory=list)
    region_avg: dict = field(default_factory=dict)  # region -> weighted OER
    source: str = "MPOB Prestasi Sawit (api/oer)"
    source_url: str = OER_API_URL
    scraped_at: str = ""

    def __post_init__(self) -> None:
        if not self.scraped_at:
            self.scraped_at = datetime.now(MYT).isoformat()


def _latest_available_month(today: Optional[datetime] = None) -> tuple[int, int]:
    """MPOB publishes the prior month's OER in arrears. Default to last month."""
    today = today or datetime.now(MYT)
    year = today.year
    month = today.month - 1
    if month == 0:
        month = 12
        year -= 1
    return year, month


def _weighted_region_average(states: list[StateOER]) -> dict:
    """FFB-tonnes-weighted OER average per SawitSense region.

    OER is the lever per RM/1% in the fair-price formula, so we weight by FFB
    processed (the volume each state contributes to the regional pool).
    """
    pools: dict[str, dict] = {}
    for s in states:
        bucket = pools.setdefault(s.region, {"oer_x_ffb": 0.0, "ffb": 0.0, "n": 0})
        bucket["oer_x_ffb"] += s.oer_cpo * s.ffb_proc_tonnes
        bucket["ffb"] += s.ffb_proc_tonnes
        bucket["n"] += 1
    out = {}
    for region, b in pools.items():
        if b["ffb"] > 0:
            out[region] = round(b["oer_x_ffb"] / b["ffb"], 2)
        elif b["n"] > 0:
            # Equal-weight fallback if all states report zero FFB throughput.
            simple = [s.oer_cpo for s in states if s.region == region]
            out[region] = round(sum(simple) / len(simple), 2) if simple else 0.0
        else:
            out[region] = 0.0
    return out


class MPOBOERScraper:
    """MPOB Prestasi Sawit OER API client."""

    def __init__(self, timeout: int = 30, max_retries: int = 2):
        self.timeout = timeout
        self.max_retries = max_retries
        self.session = requests.Session()
        self.session.headers.update(DEFAULT_HEADERS)

    def fetch(self, year: int, month: int) -> Optional[dict]:
        params = {"year": str(year), "month": f"{month:02d}"}
        for attempt in range(self.max_retries + 1):
            try:
                resp = self.session.get(OER_API_URL, params=params, timeout=self.timeout)
                resp.raise_for_status()
                return resp.json()
            except (requests.RequestException, ValueError):
                logger.warning(
                    f"OER fetch attempt {attempt + 1} failed", exc_info=True
                )
        logger.error("OER fetch failed after retries")
        return None

    def scrape(
        self,
        year: Optional[int] = None,
        month: Optional[int] = None,
    ) -> Optional[OERSnapshot]:
        """Fetch a monthly OER snapshot.

        Default month = "last full month" (MPOB publishes in arrears). If that
        month returns empty, fall back month-by-month for up to 3 months.
        Refactored into helpers to satisfy SonarCloud python:S3776.
        """
        if year is None or month is None:
            year, month = _latest_available_month()

        for back_off in range(3):  # requested month, then 1mo, 2mo earlier
            y, m = _normalize_month(year, month - back_off)
            snap = self._try_month(y, m)
            if snap is not None:
                return snap

        logger.error("OER scrape: no usable data in last 3 months")
        return None

    def _try_month(self, year: int, month: int) -> Optional[OERSnapshot]:
        """Fetch + parse a single month. Returns None when month is empty."""
        payload = self.fetch(year, month)
        if not payload:
            return None
        perf = payload.get("performance_data") or []
        state_rows = payload.get("state_data") or []
        if not perf or not state_rows:
            logger.info(f"OER {year}-{month:02d}: empty payload, falling back further")
            return None

        states = _parse_state_rows(state_rows, year, month)
        snap = _build_snapshot(perf[0], year, month, states)
        logger.info(
            f"OER {year}-{month:02d}: MY={snap.oer_malaysia}% "
            f"Pen={snap.oer_peninsular}% Sabah={snap.oer_sabah}% "
            f"Sarawak={snap.oer_sarawak}% (states={len(states)})"
        )
        return snap


# ----- Module-level helpers (kept out of the class so they're easy to test) -----

def _normalize_month(year: int, month: int) -> tuple[int, int]:
    """Wrap month <= 0 back into the previous year."""
    y, m = year, month
    while m <= 0:
        m += 12
        y -= 1
    return y, m


def _parse_state_row(
    r: dict, fallback_year: int, fallback_month: int
) -> Optional[StateOER]:
    """Parse a single state row from the OER API response. Returns None on error."""
    code = str(r.get("negeri", "")).zfill(2)
    if code not in STATE_REGION_MAP:
        return None
    name, region = STATE_REGION_MAP[code]
    try:
        return StateOER(
            state_code=code,
            state_name=name,
            region=region,
            year=str(r.get("tahun", fallback_year)),
            month=str(r.get("bulan", f"{fallback_month:02d}")).zfill(2),
            oer_cpo=float(r.get("oer_cpo", 0) or 0),
            oer_cpko=float(r.get("oer_cpko", 0) or 0),
            cpo_proc_tonnes=float(r.get("cpo_proc", 0) or 0),
            ffb_proc_tonnes=float(r.get("ffb_proc", 0) or 0),
        )
    except (TypeError, ValueError):
        logger.warning(f"OER row parse error for state {code}", exc_info=True)
        return None


def _parse_state_rows(
    state_rows: list, year: int, month: int
) -> list[StateOER]:
    """Parse the full state_data list, skipping malformed/unknown rows."""
    out: list[StateOER] = []
    for r in state_rows:
        parsed = _parse_state_row(r, year, month)
        if parsed is not None:
            out.append(parsed)
    return out


def _build_snapshot(
    p0: dict, year: int, month: int, states: list[StateOER]
) -> OERSnapshot:
    """Assemble an OERSnapshot from the API's performance_data[0] block."""
    return OERSnapshot(
        year=year,
        month=month,
        oer_malaysia=float(p0.get("oer_malaysia", 0) or 0),
        oer_peninsular=float(p0.get("oer_peninsular", 0) or 0),
        oer_sabah=float(p0.get("oer_sabah", 0) or 0),
        oer_sarawak=float(p0.get("oer_sarawak", 0) or 0),
        mill_count=int(p0.get("mill_count", 0) or 0),
        states=states,
        region_avg=_weighted_region_average(states),
    )
