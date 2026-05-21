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

# MPOB state code -> (state name, SawitSense region)
# Region mapping follows the README's 6-region grid; cross-checked against
# MPOB Peninsular sub-region conventions used in their FFB Reference Price.
STATE_REGION_MAP = {
    "01": ("Johor",            "South"),
    "02": ("Kedah",            "North"),
    "03": ("Kelantan",         "East Coast"),
    "04": ("Melaka",           "South"),
    "05": ("Negeri Sembilan",  "South"),
    "06": ("Pahang",           "East Coast"),
    "07": ("Perak",            "North"),
    "08": ("Perlis",           "North"),
    "09": ("Pulau Pinang",     "North"),
    "10": ("Selangor",         "Central"),
    "11": ("Terengganu",       "East Coast"),
    "12": ("Sabah",            "Sabah"),
    "13": ("Sarawak",          "Sarawak"),
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
        last_err: Optional[Exception] = None
        for attempt in range(self.max_retries + 1):
            try:
                resp = self.session.get(OER_API_URL, params=params, timeout=self.timeout)
                resp.raise_for_status()
                return resp.json()
            except (requests.RequestException, ValueError) as e:
                last_err = e
                logger.warning(f"OER fetch attempt {attempt + 1} failed: {e}")
        logger.error(f"OER fetch failed after retries: {last_err}")
        return None

    def scrape(
        self,
        year: Optional[int] = None,
        month: Optional[int] = None,
    ) -> Optional[OERSnapshot]:
        """Fetch a monthly OER snapshot.

        Default month = "last full month" (MPOB publishes in arrears). If that
        month returns empty, fall back month-by-month for up to 3 months.
        """
        if year is None or month is None:
            year, month = _latest_available_month()

        for back_off in range(3):  # try requested month, then 1mo, 2mo earlier
            y, m = year, month - back_off
            while m <= 0:
                m += 12
                y -= 1
            payload = self.fetch(y, m)
            if not payload:
                continue
            perf = payload.get("performance_data") or []
            state_rows = payload.get("state_data") or []
            if not perf or not state_rows:
                logger.info(f"OER {y}-{m:02d}: empty payload, falling back further")
                continue

            p0 = perf[0]
            states: list[StateOER] = []
            for r in state_rows:
                code = str(r.get("negeri", "")).zfill(2)
                if code not in STATE_REGION_MAP:
                    continue
                name, region = STATE_REGION_MAP[code]
                try:
                    states.append(StateOER(
                        state_code=code,
                        state_name=name,
                        region=region,
                        year=str(r.get("tahun", y)),
                        month=str(r.get("bulan", f"{m:02d}")).zfill(2),
                        oer_cpo=float(r.get("oer_cpo", 0) or 0),
                        oer_cpko=float(r.get("oer_cpko", 0) or 0),
                        cpo_proc_tonnes=float(r.get("cpo_proc", 0) or 0),
                        ffb_proc_tonnes=float(r.get("ffb_proc", 0) or 0),
                    ))
                except (TypeError, ValueError) as e:
                    logger.warning(f"OER row parse error for state {code}: {e}")

            snap = OERSnapshot(
                year=y,
                month=m,
                oer_malaysia=float(p0.get("oer_malaysia", 0) or 0),
                oer_peninsular=float(p0.get("oer_peninsular", 0) or 0),
                oer_sabah=float(p0.get("oer_sabah", 0) or 0),
                oer_sarawak=float(p0.get("oer_sarawak", 0) or 0),
                mill_count=int(p0.get("mill_count", 0) or 0),
                states=states,
                region_avg=_weighted_region_average(states),
            )
            logger.info(
                f"OER {y}-{m:02d}: MY={snap.oer_malaysia}% "
                f"Pen={snap.oer_peninsular}% Sabah={snap.oer_sabah}% "
                f"Sarawak={snap.oer_sarawak}% (states={len(states)})"
            )
            return snap

        logger.error("OER scrape: no usable data in last 3 months")
        return None
