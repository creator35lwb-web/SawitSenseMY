"""SawitSense Scraper Pipeline Orchestrator (v0.3 \u2014 Path C recovery).

Pipeline (post May 2026 MPOB restructure, see docs/ADR-001):
  1. Daily CPO settlement price (RM/tonne)        \u2014 scrapers.mpoc_cpo
  2. Monthly state-level OER % + region averages  \u2014 scrapers.mpob_oer
  3. Derive an INDICATIVE Price_1%_OER per region using the documented
     coefficient (see indicative_price_1pct() below) so the existing Flutter
     Fair Price calculator keeps working. This is clearly labelled
     `is_indicative: true` and `formula_status: \"INDICATIVE\"` in the output
     payload so the frontend can show an honest banner.
  4. (Legacy) Try BEPI scrapers \u2014 currently expected to fail; will reactivate
     automatically the day MPOB restores anonymous access.
  5. (Legacy) Commodities-API CPO fallback if MPOC also fails.
  6. Write Firestore + JSON.

Exit code 0 = success, 1 = failure (for GitHub Actions).

Original author: QQ (Qoder CSO)
Recovery patch:  QQ (Perplexity) \u2014 on behalf of YSenseAI / CIO XV (May 2026)
"""

import logging
import sys
from dataclasses import asdict
from datetime import datetime, timedelta, timezone
from typing import Optional

from monitor.health_check import report_failure, report_success
from scrapers.commodities_fallback import fetch_cpo_fallback
from scrapers.mpob_bepi import MPOBScraper, REGIONS
from scrapers.mpob_oer import MPOBOERScraper
from scrapers.mpoc_cpo import MPOCDailyCPOScraper
from writer.firestore_writer import write_price_data

MYT = timezone(timedelta(hours=8))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("sawitsense")


# Indicative coefficient mapping CPO -> RM per 1% OER, derived from the
# historical relationship MPOB used to publish: roughly
#   Price_1%OER \u2248 CPO * 0.01 * dealer_share_factor
# where dealer_share_factor reflects mill margin + transport + grading buffer.
# The 0.01 part is exact (OER is in %), the share factor we anchor at 0.93
# per the project's calibrated review of PV-85935 and the README South-region
# example (CPO ~RM 2,624, Price_1% ~RM 24.40 => factor \u2248 0.93). This is
# documented in docs/ADR-001 and surfaced to users as "indicative".
DEFAULT_INDICATIVE_SHARE_FACTOR = 0.93


def indicative_price_1pct(cpo_price: float, share_factor: float = DEFAULT_INDICATIVE_SHARE_FACTOR) -> float:
    """Derive an indicative RM-per-1%-OER from a CPO settlement price.

    NOT a substitute for the official MPOB FFB Reference Price. Used solely
    to keep the Fair Price calculator producing a smallholder-protective
    GREEN/AMBER/RED verdict while we restore the authoritative source.
    """
    if cpo_price is None or cpo_price <= 0:
        return 0.0
    return round(cpo_price * 0.01 * share_factor, 2)


INDICATIVE_NOTICE = (
    "MPOB's daily FFB Reference Price tables moved behind a licensee "
    "login (May 2026). Until restored, regional Price_1%OER values "
    "shown are INDICATIVE \u2014 derived from MPOC daily CPO settlement "
    "and MPOB Prestasi Sawit monthly OER. Use as guidance, not as a "
    "legal benchmark. Track restoration: ADR-001."
)

DERIVED_SOURCE_LABEL = "Derived (MPOC CPO \u00d7 MPOB OER)"
DERIVED_FFB_SOURCE = "SawitSense derived (Path C)"


def _empty_payload() -> dict:
    """Initial payload skeleton with all Path C flags set."""
    now_iso = datetime.now(MYT).isoformat()
    return {
        "scraped_at": now_iso,
        "updated_at": now_iso,
        "success": False,
        "data_source_version": "0.3-recovery",
        "formula_status": "INDICATIVE",
        "is_indicative": True,
        "indicative_notice": INDICATIVE_NOTICE,
        "cpo": None,
        "ffb": None,
        "oer": None,
        "fallback_used": False,
        "legacy_bepi_attempted": True,
        "legacy_bepi_success": False,
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


def _derive_ffb_block(payload: dict) -> Optional[dict]:
    """Build the indicative FFB regional block from the payload's cpo + oer."""
    cpo_block = payload.get("cpo") or {}
    cpo_price = cpo_block.get("price_myr_per_tonne")
    if not cpo_price:
        return None

    p1 = indicative_price_1pct(cpo_price)
    oer_block = payload.get("oer") or {}
    region_avg = oer_block.get("region_avg") or {}

    regions_out = []
    for region in REGIONS:
        oer_pct = _resolve_region_oer(region, region_avg, oer_block)
        fair_price = round(p1 * float(oer_pct), 2) if oer_pct else None
        regions_out.append({
            "region": region,
            "price_1pct_oer": p1,
            "indicative_oer_pct": oer_pct,
            "indicative_fair_price_per_tonne": fair_price,
            "source": DERIVED_SOURCE_LABEL,
            "is_indicative": True,
        })

    return {
        "date": cpo_block.get("date"),
        "regions": regions_out,
        "cpo_price": cpo_price,
        "is_indicative": True,
        "source": DERIVED_FFB_SOURCE,
    }


def build_payload(cpo_obs, oer_snap, legacy_attempt, fallback_obs):
    """Compose the SawitSense data payload (matches frontend price_provider).

    Behavior is identical to v0.3-recovery initial. Refactored into helpers
    for cognitive-complexity compliance — see SonarCloud python:S3776.
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

    # --- Derived FFB regional indicative benchmark ---
    ffb = _derive_ffb_block(payload)
    if ffb is not None:
        payload["ffb"] = ffb

    payload["success"] = bool(payload["cpo"] or payload["ffb"] or payload["oer"])
    payload["legacy_bepi_success"] = bool(legacy_attempt)
    return payload


def main() -> int:
    logger.info(f"SawitSense scraper starting at {datetime.now(MYT).isoformat()}")

    # --- Step 1: try the legacy BEPI scraper (will fail until MPOB restores) ---
    legacy_payload = None
    try:
        legacy_payload = MPOBScraper().scrape_all()
        if legacy_payload.get("success"):
            logger.info("Legacy MPOB BEPI scrape unexpectedly succeeded \u2014 reverting to authoritative path.")
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

    # --- Step 3: Commodities-API CPO fallback if MPOC failed AND we have a key ---
    fallback_cpo = None
    if cpo_latest is None:
        logger.info("Trying Commodities-API CPO fallback...")
        fallback_cpo = fetch_cpo_fallback()
        if fallback_cpo:
            logger.info(f"Commodities-API fallback OK: RM {fallback_cpo.get('price_myr_per_tonne')}/t")

    # --- Step 4: assemble payload ---
    payload = build_payload(cpo_latest, oer_snap, legacy_ok, fallback_cpo)

    if not payload["success"]:
        logger.error("All data sources failed (MPOC CPO, MPOB OER, Commodities fallback).")
        report_failure("All SawitSense data sources failed")
        # Still attempt to write a stale-marker so dashboards know we tried.
        payload["error"] = "all_sources_failed"
        write_price_data(payload)
        return 1

    written = write_price_data(payload)
    if not written:
        logger.error("Failed to write price data to JSON/Firestore")
        report_failure("Data write failed")
        return 1

    report_success()
    logger.info("Pipeline complete. Indicative data written. (Legacy authoritative path = pending MPOB restoration.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
