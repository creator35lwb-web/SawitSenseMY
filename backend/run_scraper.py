"""SawitSense Scraper Pipeline Orchestrator (v0.4 \u2014 MPOB's official daily price).

Pipeline (see docs/ADR-002):
  1. Daily CPO settlement price (RM/tonne)        \u2014 scrapers.mpoc_cpo
  2. Monthly state-level OER % + region averages  \u2014 scrapers.mpob_oer
  3. MPOB's daily FFB reference price per 1% OER for each region, at the
     mill gate                                    \u2014 scrapers.mpob_ffb
     Until D22 (Oct 2026) this step was SawitSense's own estimate,
     CPO x 0.01 x 0.93 (ADR-001), which was 6-11% off in the Peninsula (K25).
  4. (Legacy) Try BEPI scrapers \u2014 expected to fail, and not used for prices.
  5. (Legacy) Commodities-API CPO fallback if MPOC also fails.
  6. Write the JSON snapshots (backend/data/), which the deploy publishes.

Exit code 0 = success, 1 = failure (for GitHub Actions).

Original author: QQ (Qoder CSO)
Recovery patch:  QQ (Perplexity), May 2026 \u2014 under Alton's authority (part of the YSenseAI ecosystem)
Patch:           SS (Claude Code), Sep 2026 \u2014 data-quality `warnings` in the payload;
                 Firestore retired (JSON only); a failed source never replaces
                 the last good data (K7, see decide_payload)
Patch:           SS (Claude Code), Oct 2026 \u2014 `oer.in_app_since`, the date each
                 OER month first appeared, so the app can say what is new
                 from MPOB (D18)
Patch:           SS (Claude Code), Oct 2026 \u2014 MPOB's official daily FFB
                 reference price replaces the estimate (D22, K25, ADR-002)
"""

import logging
import sys
from dataclasses import asdict
from datetime import date, datetime, timedelta, timezone
from typing import Optional

from monitor.health_check import report_failure, report_success
from scrapers.commodities_fallback import fetch_cpo_fallback
from scrapers.mpob_bepi import MPOBScraper, REGIONS
from scrapers.mpob_ffb import MPOBFFBScraper
from scrapers.mpob_oer import MPOBOERScraper
from scrapers.mpoc_cpo import MPOCDailyCPOScraper
from writer.json_writer import read_latest, write_price_data

MYT = timezone(timedelta(hours=8))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("sawitsense")


# Seconds to wait for MPOB's legacy BEPI pages. They are expected to fail (a
# licensee login since May 2026), so when MPOB's server doesn't answer this
# attempt mustn't use up the job's 10-minute limit (21 Oct 2026, K23).
LEGACY_BEPI_TIMEOUT = 10

# A payload from before D22 holds SawitSense's own estimate (CPO x 0.01 x
# 0.93). If MPOB's daily summary can't be read on the first run after the
# switch, that block is kept, still labelled indicative, until it can (K7).
CARRIED_ESTIMATE_NOTICE = (
    "These regional prices are SawitSense's earlier estimate (CPO x 0.01 x 0.93), "
    "kept until MPOB's daily FFB reference price can be read (D22)."
)

# A fresh MPOB price this many days old means MPOB has stopped updating its
# summary; weekends and public holidays alone account for up to about 5.
MAX_FFB_AGE_DAYS = 6
# MPOB's price per 1% OER ran at 0.88-1.04 x (CPO x 0.01) in October 2026:
# about 1.01 in the Peninsula and 0.90-0.92 in East Malaysia. Outside this
# range a figure is more likely misread than real, so it raises a warning.
FFB_TO_CPO_RANGE = (0.8, 1.2)
# MPOB's footnote for its Sarawak column, which the app translates.
SARAWAK_NOTE = "Miri & Bintulu"


def _empty_payload() -> dict:
    """Initial payload skeleton; build_payload() sets the mode from the ffb block."""
    now_iso = datetime.now(MYT).isoformat()
    return {
        "scraped_at": now_iso,
        "updated_at": now_iso,
        "success": False,
        "data_source_version": "0.4-mpob-daily",
        "formula_status": "OFFICIAL",
        "is_indicative": False,
        "indicative_notice": None,
        "cpo": None,
        "ffb": None,
        "oer": None,
        "fallback_used": False,
        "legacy_bepi_attempted": True,
        "legacy_bepi_success": False,
        "warnings": [],
    }


def _cpo_dict(cpo_obs) -> dict:
    """Serialize an MPOCDailyCPO observation to the payload's cpo block."""
    return {
        "date": cpo_obs.date_iso,
        "date_raw": cpo_obs.date_raw,
        "price_myr_per_tonne": cpo_obs.price_myr_per_tonne,
        "source": cpo_obs.source,
        "source_url": cpo_obs.source_url,
        "scraped_at": cpo_obs.scraped_at,
    }


def _oer_dict(oer_snap) -> dict:
    """Serialize an OERSnapshot to the payload's oer block."""
    return {
        "year": oer_snap.year,
        "month": oer_snap.month,
        "oer_malaysia": oer_snap.oer_malaysia,
        "oer_peninsular": oer_snap.oer_peninsular,
        "oer_sabah": oer_snap.oer_sabah,
        "oer_sarawak": oer_snap.oer_sarawak,
        "mill_count": oer_snap.mill_count,
        "region_avg": oer_snap.region_avg,
        "states": [asdict(s) for s in oer_snap.states],
        "source": oer_snap.source,
        "source_url": oer_snap.source_url,
        "source_page_url": oer_snap.source_page_url,
        "scraped_at": oer_snap.scraped_at,
    }


def _resolve_region_oer(region: str, region_avg: dict, oer_block: dict) -> Optional[float]:
    """Pick the OER % to use for a SawitSense region.

    Preference order: region-specific weighted average -> national fallback
    (Sabah/Sarawak get their own national OERs; all other regions fall back
    to Peninsular).
    """
    explicit = region_avg.get(region)
    if explicit is not None:
        return explicit
    if region == "Sabah":
        return oer_block.get("oer_sabah")
    if region == "Sarawak":
        return oer_block.get("oer_sarawak")
    return oer_block.get("oer_peninsular")


def _ffb_dict(ffb_obs, oer_block: Optional[dict]) -> dict:
    """The payload's ffb block: MPOB's price per 1% OER for each region, at the
    mill gate (D22), with MPOB's average OER for the region beside it."""
    oer_block = oer_block or {}
    region_avg = oer_block.get("region_avg") or {}
    regions_out = []
    for region in REGIONS:
        entry = {
            "region": region,
            "date": ffb_obs.dates[region],
            "price_1pct_oer": ffb_obs.prices[region],
            "avg_oer_pct": _resolve_region_oer(region, region_avg, oer_block),
            "source": ffb_obs.source,
            "is_indicative": False,
        }
        if region == "Sarawak" and ffb_obs.sarawak_note:
            entry["note"] = ffb_obs.sarawak_note
        regions_out.append(entry)
    return {
        "date": ffb_obs.date_iso,
        "regions": regions_out,
        "unit": "RM per tonne of FFB per 1% OER, at the mill gate",
        "source": ffb_obs.source,
        "source_url": ffb_obs.source_url,
        "mpob_last_update": ffb_obs.last_update,
        "is_indicative": False,
        "scraped_at": ffb_obs.scraped_at,
    }


def _set_mode(payload: dict) -> None:
    """Official, unless the ffb block is an estimate carried forward from before D22."""
    indicative = bool((payload.get("ffb") or {}).get("is_indicative"))
    payload["is_indicative"] = indicative
    payload["formula_status"] = "INDICATIVE" if indicative else "OFFICIAL"
    payload["indicative_notice"] = CARRIED_ESTIMATE_NOTICE if indicative else None


def ffb_quality_warnings(ffb_obs, cpo_price: Optional[float], today: str) -> list:
    """Checks on a fresh MPOB read: its age, each price against the CPO price,
    and the Sarawak footnote that the app translates."""
    warnings = []
    age = (date.fromisoformat(today) - date.fromisoformat(ffb_obs.date_iso)).days
    if age > MAX_FFB_AGE_DAYS:
        warnings.append(f"MPOB's latest daily FFB price is from {ffb_obs.date_iso}, {age} days ago")
    if cpo_price:
        low, high = FFB_TO_CPO_RANGE
        for region, price in ffb_obs.prices.items():
            ratio = price / (cpo_price * 0.01)
            if not low <= ratio <= high:
                warnings.append(
                    f"MPOB's {region} price, RM {price:.2f} per 1% OER, is {ratio:.0%} of CPO x 0.01 "
                    f"(CPO RM {cpo_price:.0f}); check it against MPOB's PDF"
                )
    if ffb_obs.sarawak_note not in (None, SARAWAK_NOTE):
        warnings.append(f"MPOB's Sarawak footnote now reads {ffb_obs.sarawak_note!r}; update the app's wording")
    return warnings


def build_payload(cpo_obs, oer_snap, legacy_attempt, fallback_obs, previous_oer: Optional[dict] = None,
                  ffb_obs=None, previous_ffb: Optional[dict] = None):
    """Compose the SawitSense data payload (matches frontend price_provider).

    Behavior is identical to v0.3-recovery initial. Refactored into helpers
    for cognitive-complexity compliance — see SonarCloud python:S3776.
    `previous_oer` and `previous_ffb` (the last published blocks) are carried
    forward when this run's OER or MPOB FFB fetch failed; see decide_payload().
    """
    payload = _empty_payload()

    # --- CPO leg (primary or fallback) ---
    if cpo_obs is not None:
        payload["cpo"] = _cpo_dict(cpo_obs)
    elif fallback_obs is not None:
        payload["cpo"] = fallback_obs
        payload["fallback_used"] = True

    # --- OER leg ---
    if oer_snap is not None:
        payload["oer"] = _oer_dict(oer_snap)
    elif previous_oer:
        # MPOB publishes OER monthly, so the last published figures are still
        # the latest available. Keep them, marked, rather than drop regional OER.
        payload["oer"] = {**previous_oer, "carried_forward": True}

    # --- MPOB's official daily FFB reference price (D22) ---
    if ffb_obs is not None:
        payload["ffb"] = _ffb_dict(ffb_obs, payload["oer"])
    elif previous_ffb:
        # Keep the last prices, with their date, rather than show none (K7).
        payload["ffb"] = {**previous_ffb, "carried_forward": True}
    _set_mode(payload)

    payload["success"] = bool(payload["cpo"] or payload["ffb"] or payload["oer"])
    payload["legacy_bepi_success"] = bool(legacy_attempt)
    payload["warnings"] = _collect_warnings(cpo_obs, oer_snap, fallback_obs, previous_oer, ffb_obs, previous_ffb)
    if ffb_obs is not None:
        cpo_price = (payload["cpo"] or {}).get("price_myr_per_tonne")
        payload["warnings"] += ffb_quality_warnings(ffb_obs, cpo_price, payload["scraped_at"][:10])
    return payload


def _collect_warnings(cpo_obs, oer_snap, fallback_obs, previous_oer: Optional[dict] = None,
                      ffb_obs=None, previous_ffb: Optional[dict] = None) -> list:
    """Data-quality problems for this run. The data is still published; the
    scraper workflow turns a non-empty list into an alert issue."""
    warnings = []
    if cpo_obs is None:
        warnings.append(
            "MPOC daily CPO price unavailable; Commodities-API fallback used"
            if fallback_obs is not None
            else "MPOC daily CPO price unavailable; no CPO price this run"
        )
    if oer_snap is not None:
        warnings.extend(oer_snap.warnings)
    elif previous_oer:
        month = previous_oer.get("month")
        period = f"{previous_oer.get('year')}-{month:02d}" if isinstance(month, int) else "previous run"
        warnings.append(f"MPOB OER unavailable this run; kept the previous figures ({period})")
    else:
        warnings.append("MPOB OER data unavailable; no regional OER this run")
    if ffb_obs is None:
        warnings.append(
            f"MPOB daily FFB reference price unavailable this run; kept the previous prices "
            f"({previous_ffb.get('date')})" if previous_ffb
            else "MPOB daily FFB reference price unavailable; no regional prices this run"
        )
    return warnings


# The date each OER month first appeared in SawitSense, for the month that
# arrived before the scraper recorded it (D18). From the data commits on main:
# September 2026 first appears in 533bd08, on 12 Oct 2026 at 13:49 MYT.
OER_IN_APP_SINCE_BEFORE_TRACKING = {(2026, 9): "2026-10-12"}


def oer_in_app_since(oer: dict, last_oer: Optional[dict], today: str) -> Optional[str]:
    """The date (YYYY-MM-DD, MYT) this OER month first appeared in SawitSense.

    A new month is dated today; the same month keeps the date it already has.
    None means the date is unknown, and the app then leaves it out.
    """
    period = (oer.get("year"), oer.get("month"))
    if not last_oer or (last_oer.get("year"), last_oer.get("month")) != period:
        return today
    return last_oer.get("in_app_since") or OER_IN_APP_SINCE_BEFORE_TRACKING.get(period)


def decide_payload(cpo_obs, oer_snap, legacy_attempt, fallback_obs, previous: Optional[dict],
                   ffb_obs=None) -> Optional[dict]:
    """The payload to publish this run, or None to keep the last good snapshot.

    Never replace good data with worse data (K7):
    - No CPO price this run (MPOC and the fallback both failed): publish
      nothing. The last good snapshot stays live and its freshness badge ages
      honestly, instead of the site losing its prices until the next good run.
    - OER missing this run: carry the previous `oer` block forward, marked
      `carried_forward`, with a warning.
    - MPOB's daily FFB price missing this run: carry the previous `ffb` block
      forward the same way, so the last official prices stay up with their
      date (D22).

    A fresh `oer` block also records `in_app_since` (D18).
    """
    if cpo_obs is None and fallback_obs is None:
        return None
    last_oer = (previous or {}).get("oer")
    payload = build_payload(cpo_obs, oer_snap, legacy_attempt, fallback_obs,
                            previous_oer=last_oer if oer_snap is None else None,
                            ffb_obs=ffb_obs,
                            previous_ffb=(previous or {}).get("ffb") if ffb_obs is None else None)
    if oer_snap is not None:
        # scraped_at is in MYT, so its first 10 characters are today's MYT date.
        payload["oer"]["in_app_since"] = oer_in_app_since(payload["oer"], last_oer, payload["scraped_at"][:10])
    return payload


def main() -> int:
    logger.info(f"SawitSense scraper starting at {datetime.now(MYT).isoformat()}")

    # --- Step 1: try the legacy BEPI scraper (will fail until MPOB restores) ---
    legacy_payload = None
    try:
        legacy_payload = MPOBScraper(timeout=LEGACY_BEPI_TIMEOUT).scrape_all()
        if legacy_payload.get("success"):
            # The prices come from MPOB's daily FFB summary (D22), so say plainly
            # that this source isn't used.
            logger.warning(
                "Legacy MPOB BEPI returned data. It isn't used: the prices come from "
                "MPOB's daily FFB reference price summary (D22)."
            )
    except Exception as e:  # never crash on legacy path
        logger.info(f"Legacy BEPI scrape error (expected): {e}")

    legacy_ok = bool(legacy_payload and legacy_payload.get("success"))

    # --- Step 2: primary public sources ---
    cpo_obs = MPOCDailyCPOScraper().scrape()
    cpo_latest = cpo_obs.latest if cpo_obs else None
    if cpo_latest:
        logger.info(f"CPO (MPOC): {cpo_latest.date_iso} = RM {cpo_latest.price_myr_per_tonne}/t")
    else:
        logger.warning("MPOC CPO scrape returned no data")

    oer_snap = MPOBOERScraper().scrape()
    if oer_snap:
        logger.info(f"OER (MPOB Prestasi): {oer_snap.year}-{oer_snap.month:02d} avg = {oer_snap.oer_malaysia}%")
    else:
        logger.warning("MPOB OER scrape returned no data")

    ffb_obs = MPOBFFBScraper().scrape()
    if ffb_obs is None:
        logger.warning("MPOB daily FFB reference price unavailable this run")

    # --- Step 3: Commodities-API CPO fallback if MPOC failed AND we have a key ---
    fallback_cpo = None
    if cpo_latest is None:
        logger.info("Trying Commodities-API CPO fallback...")
        fallback_cpo = fetch_cpo_fallback()
        if fallback_cpo:
            logger.info(f"Commodities-API fallback OK: RM {fallback_cpo.get('price_myr_per_tonne')}/t")

    # --- Step 4: assemble payload, never replacing good data with worse ---
    payload = decide_payload(cpo_latest, oer_snap, legacy_ok, fallback_cpo, read_latest(), ffb_obs=ffb_obs)

    if payload is None:
        logger.error(
            "No CPO price this run (MPOC and the Commodities fallback both failed). "
            "Keeping the last good snapshot; its freshness badge will show its age."
        )
        report_failure("No CPO price this run; last good snapshot kept")
        return 1

    for warning in payload["warnings"]:
        logger.warning(f"Data-quality warning: {warning}")

    written = write_price_data(payload)
    if not written:
        logger.error("Failed to write the price data JSON")
        report_failure("Data write failed")
        return 1

    report_success()
    ffb = payload.get("ffb") or {}
    logger.info(f"Pipeline complete. Regional prices: {ffb.get('source', 'none')}, {ffb.get('date', '-')}"
                + (" (carried forward)" if ffb.get("carried_forward") else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
