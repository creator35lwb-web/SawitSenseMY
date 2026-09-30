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

Author: QQ (Perplexity), May 2026 — recovery patch under Alton's authority
(part of the YSenseAI ecosystem).
Original SawitSense data layer authored by QQ (Qoder CSO).
Patch: SS (Claude Code), Sep 2026 — MPOB state codes corrected (Sabah = 13,
Sarawak = 14) and a cross-check against MPOB's published totals added.
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
# Public page showing the same figures, with month/year pickers. Linked from
# the app so smallholders can check the OER themselves (the API returns JSON).
OER_PAGE_URL = "https://prestasisawit.mpob.gov.my/en/oer"

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
#
# MPOB numbers the Peninsular states alphabetically, then Sabah = 13 and
# Sarawak = 14. This is NOT the JPN/ISO numbering (Sabah = 12, Sarawak = 13)
# that this map originally assumed, which published Sabah's OER as Sarawak's
# and dropped Sarawak's row. Verified against the live API (Aug 2026): rows 13
# and 14 reproduce MPOB's own oer_sabah (21.06) and oer_sarawak (19.58)
# exactly. Codes 08 and 12 have not been seen in responses; 08 stays Perlis
# (alphabetical order) and 12 is left unmapped. _cross_check() catches drift.
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
    "13": ("Sabah",            REGION_SABAH),
    "14": ("Sarawak",          REGION_SARAWAK),
}

PENINSULAR_REGIONS = {REGION_NORTH, REGION_SOUTH, REGION_CENTRAL, REGION_EAST_COAST}

# Allowed gap (percentage points) between our aggregation of the state rows and
# MPOB's published Sabah / Sarawak / Peninsular OER. MPOB rounds to 2 dp; a
# Sabah/Sarawak mix-up moves the figures by ~1.5 points.
CROSS_CHECK_TOLERANCE = 0.1

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
    warnings: list = field(default_factory=list)  # data-quality problems found while parsing
    source: str = "MPOB Prestasi Sawit (api/oer)"
    source_url: str = OER_API_URL
    source_page_url: str = OER_PAGE_URL
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


def _weighted_oer(states: list[StateOER]) -> Optional[float]:
    """FFB-tonnes-weighted OER across `states`; None if they report no FFB."""
    ffb = sum(s.ffb_proc_tonnes for s in states)
    if ffb <= 0:
        return None
    return round(sum(s.oer_cpo * s.ffb_proc_tonnes for s in states) / ffb, 2)


def _weighted_region_average(states: list[StateOER]) -> dict:
    """FFB-tonnes-weighted OER average per SawitSense region.

    OER is the lever per RM/1% in the fair-price formula, so we weight by FFB
    processed (the volume each state contributes to the regional pool).
    """
    out = {}
    for region in dict.fromkeys(s.region for s in states):
        members = [s for s in states if s.region == region]
        avg = _weighted_oer(members)
        if avg is None:
            # Equal-weight fallback if all states report zero FFB throughput.
            avg = round(sum(s.oer_cpo for s in members) / len(members), 2)
        out[region] = avg
    return out


def _cross_check(states: list[StateOER], p0: dict) -> list[str]:
    """Compare our aggregation of the state rows with MPOB's published totals.

    Returns one message per mismatch (empty = consistent). A wrong state-code
    mapping, like the Sabah/Sarawak mix-up found in Sep 2026, shows up here.
    """
    groups = [
        ("Sabah", [s for s in states if s.region == REGION_SABAH], p0.get("oer_sabah")),
        ("Sarawak", [s for s in states if s.region == REGION_SARAWAK], p0.get("oer_sarawak")),
        ("Peninsular", [s for s in states if s.region in PENINSULAR_REGIONS], p0.get("oer_peninsular")),
    ]
    problems = []
    for label, members, published in groups:
        if not published:
            continue
        ours = _weighted_oer(members)
        if ours is None or abs(ours - float(published)) > CROSS_CHECK_TOLERANCE:
            problems.append(
                f"MPOB OER cross-check failed for {label}: the state rows mapped there "
                f"give {ours}%, but MPOB publishes {published}%"
            )
    return problems


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

        states, warnings = _parse_state_rows(state_rows, year, month)
        snap = _build_snapshot(perf[0], year, month, states, warnings)
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
) -> tuple[list[StateOER], list[str]]:
    """Parse the full state_data list, skipping malformed/unknown rows.

    Returns (states, warnings). A row whose state code is missing from
    STATE_REGION_MAP produces a warning when it carries FFB volume, because
    real data is being dropped.
    """
    out: list[StateOER] = []
    warnings: list[str] = []
    for r in state_rows:
        code = str(r.get("negeri", "")).zfill(2)
        if code not in STATE_REGION_MAP:
            try:
                ffb = float(r.get("ffb_proc") or 0)
            except (TypeError, ValueError):
                ffb = 0.0
            if ffb > 0:
                warnings.append(
                    f"MPOB OER row for unknown state code {code!r} ({ffb:,.0f} t FFB) was skipped"
                )
            continue
        parsed = _parse_state_row(r, year, month)
        if parsed is not None:
            out.append(parsed)
    return out, warnings


def _build_snapshot(
    p0: dict, year: int, month: int, states: list[StateOER], warnings: Optional[list] = None
) -> OERSnapshot:
    """Assemble an OERSnapshot from the API's performance_data[0] block."""
    warnings = list(warnings or [])
    region_avg = _weighted_region_average(states)
    mismatches = _cross_check(states, p0)
    if mismatches:
        # Don't publish per-region figures that don't reconcile with MPOB's own
        # totals; run_scraper then falls back to MPOB's published Sabah,
        # Sarawak and Peninsular OER for every region.
        region_avg = {}
        warnings.extend(mismatches)
    for w in warnings:
        logger.warning(w)
    return OERSnapshot(
        year=year,
        month=month,
        oer_malaysia=float(p0.get("oer_malaysia", 0) or 0),
        oer_peninsular=float(p0.get("oer_peninsular", 0) or 0),
        oer_sabah=float(p0.get("oer_sabah", 0) or 0),
        oer_sarawak=float(p0.get("oer_sarawak", 0) or 0),
        mill_count=int(p0.get("mill_count", 0) or 0),
        states=states,
        region_avg=region_avg,
        warnings=warnings,
    )
