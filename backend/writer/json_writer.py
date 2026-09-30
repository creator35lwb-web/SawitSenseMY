"""JSON writer for SawitSense.

Writes each price snapshot to backend/data/ as latest.json and as that day's
prices_YYYY-MM-DD.json, plus a small history.json index of daily CPO prices.
The deploy publishes these files to GitHub Pages, where the app reads them.

Author: QQ (Qoder CSO)
Patch: SS (Claude Code), Sep 2026 — Firestore removed (Alton's decision D5).
It was never configured and the app never read it, so every run logged a
false "Firestore write failed" error. Renamed from firestore_writer.py.
Patch: SS (Claude Code), Sep 2026 — history.json, so the History tab makes one
request instead of one per day (30 requests on a rural connection).
"""

import json
import logging
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
JSON_DIR = Path(__file__).parent.parent / "data"
LATEST_FILE = "latest.json"
HISTORY_FILE = "history.json"
# Entries kept in history.json; the History tab shows the last 30 days.
HISTORY_ENTRIES = 60


def read_latest() -> Optional[dict]:
    """The last published snapshot (latest.json), or None if missing or unreadable."""
    try:
        return json.loads((JSON_DIR / LATEST_FILE).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None


def write_to_json(data: dict, filename: str = LATEST_FILE) -> bool:
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

    json_ok = write_to_json(data, LATEST_FILE)

    today = datetime.now(MYT).strftime("%Y-%m-%d")
    date_str = data["cpo"].get("date", today) if data.get("cpo") else today
    write_to_json(data, f"prices_{date_str}.json")
    write_history()

    return json_ok


def write_history(max_entries: int = HISTORY_ENTRIES) -> bool:
    """Write history.json: the daily CPO prices from the prices_*.json files,
    oldest first, so the History tab needs one small request."""
    days = {}
    for path in JSON_DIR.glob("prices_*.json"):
        try:
            cpo = json.loads(path.read_text(encoding="utf-8")).get("cpo") or {}
        except (OSError, ValueError):
            continue
        if cpo.get("date") and cpo.get("price_myr_per_tonne"):
            days[cpo["date"]] = cpo["price_myr_per_tonne"]
    entries = [{"date": d, "cpo_price": days[d]} for d in sorted(days)][-max_entries:]
    return write_to_json(
        {"generated_at": datetime.now(MYT).isoformat(), "days": entries}, HISTORY_FILE
    )
