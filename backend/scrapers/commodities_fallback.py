"""Commodities API Fallback for SawitSense.

Used when MPOB BEPI scraper fails.
Provides CPO spot price from Commodities-API (free tier).

Author: QQ (Qoder CSO)
"""

import os
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional

import requests

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
COMMODITIES_API_URL = "https://commodities-api.com/api/latest"


def fetch_cpo_fallback(api_key: Optional[str] = None) -> Optional[dict]:
    """Fetch CPO price from Commodities-API as fallback.

    Args:
        api_key: Commodities-API key. Falls back to COMMODITIES_API_KEY env var.

    Returns:
        Dict with price data or None on failure.
    """
    key = api_key or os.environ.get("COMMODITIES_API_KEY")
    if not key:
        logger.warning("No Commodities-API key available for fallback")
        return None

    try:
        resp = requests.get(
            COMMODITIES_API_URL,
            params={
                "access_key": key,
                "base": "MYR",
                "symbols": "PALM_OIL",
            },
            timeout=15,
        )
        resp.raise_for_status()
        data = resp.json()

        if not data.get("success"):
            logger.error(f"Commodities-API returned error: {data}")
            return None

        rates = data.get("data", {}).get("rates", {})
        palm_rate = rates.get("PALM_OIL")

        if palm_rate is None:
            logger.error("No PALM_OIL rate in response")
            return None

        return {
            "date": data.get("data", {}).get("date", datetime.now(MYT).strftime("%Y-%m-%d")),
            "price_myr_per_tonne": round(1 / palm_rate, 2) if palm_rate > 0 else None,
            "source": "Commodities-API (fallback)",
            "scraped_at": datetime.now(MYT).isoformat(),
        }

    except requests.RequestException as e:
        logger.error(f"Commodities-API fallback failed: {e}")
        return None
