"""JSON writer for SawitSense.

Writes each price snapshot to backend/data/ as latest.json and as that day's
prices_YYYY-MM-DD.json. The deploy publishes these files to GitHub Pages,
where the app reads them.

Author: QQ (Qoder CSO)
Patch: SS (Claude Code), Sep 2026 — Firestore removed (Alton's decision D5).
It was never configured and the app never read it, so every run logged a
false "Firestore write failed" error. Renamed from firestore_writer.py.
"""

import json
import logging
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
JSON_DIR = Path(__file__).parent.parent / "data"


def read_latest() -> Optional[dict]:
    """The last published snapshot (latest.json), or None if missing or unreadable."""
    try:
        return json.loads((JSON_DIR / "latest.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def write_to_json(data: dict, filename: str = "latest.json") -> bool:
    """Write data to backend/data/<filename>."""
    try:
        JSON_DIR.mkdir(parents=True, exist_ok=True)
        filepath = JSON_DIR / filename
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        logger.info(f"Written: {filepath}")
        return True
    except OSError:
        logger.exception("JSON write failed")
        return False


def write_price_data(data: dict) -> bool:
    """Write the snapshot as latest.json and as that day's prices file."""
    data["updated_at"] = datetime.now(MYT).isoformat()

    json_ok = write_to_json(data, "latest.json")

    today = datetime.now(MYT).strftime("%Y-%m-%d")
    date_str = data["cpo"].get("date", today) if data.get("cpo") else today
    write_to_json(data, f"prices_{date_str}.json")

    return json_ok
