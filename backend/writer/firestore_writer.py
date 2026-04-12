"""Firestore + JSON writer for SawitSense.

Writes scraped data to Firestore (primary) and local JSON (fallback).

Firestore schema:
  sawitsense_latest/current  -> latest prices
  sawitsense_prices/{date}   -> daily price history

Author: QQ (Qoder CSO)
"""

import json
import logging
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
JSON_FALLBACK_DIR = Path(__file__).parent.parent / "data"


def write_to_json(data: dict, filename: str = "latest.json") -> bool:
    """Write data to local JSON file as fallback."""
    try:
        JSON_FALLBACK_DIR.mkdir(parents=True, exist_ok=True)
        filepath = JSON_FALLBACK_DIR / filename
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        logger.info(f"Written to JSON fallback: {filepath}")
        return True
    except (IOError, OSError) as e:
        logger.error(f"JSON write failed: {e}")
        return False


def write_to_firestore(data: dict, collection: str = "sawitsense_latest", doc_id: str = "current") -> bool:
    """Write data to Firestore.

    Requires GOOGLE_APPLICATION_CREDENTIALS or Firebase service account.
    Falls back to JSON if Firestore is not configured.
    """
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore

        if not firebase_admin._apps:
            cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
            if cred_path:
                cred = credentials.Certificate(cred_path)
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()

        db = firestore.client()
        db.collection(collection).document(doc_id).set(data)
        logger.info(f"Written to Firestore: {collection}/{doc_id}")
        return True

    except ImportError:
        logger.warning("firebase-admin not installed. Using JSON fallback.")
        return False
    except Exception as e:
        logger.error(f"Firestore write failed: {e}")
        return False


def write_price_data(data: dict) -> bool:
    """Write price data to both Firestore and JSON.

    Always writes JSON (for GitHub Pages static fallback).
    Attempts Firestore write if configured.
    """
    data["updated_at"] = datetime.now(MYT).isoformat()

    json_ok = write_to_json(data, "latest.json")

    date_str = data.get("cpo", {}).get("date", datetime.now(MYT).strftime("%Y-%m-%d")) if data.get("cpo") else datetime.now(MYT).strftime("%Y-%m-%d")
    write_to_json(data, f"prices_{date_str}.json")

    firestore_ok = write_to_firestore(data)

    if not firestore_ok:
        logger.info("Firestore unavailable. JSON fallback active.")

    return json_ok
