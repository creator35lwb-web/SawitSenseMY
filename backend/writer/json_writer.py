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
Patch: SS (Claude Code), Nov 2026 — history.json also keeps MPOB's daily price
per 1% OER for each region (D26).
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


def write_price_data(data: dict, ffb_days: Optional[list] = None) -> bool:
    """Write the snapshot as latest.json and as that day's prices file.

    `ffb_days` are MPOB's daily prices read this run, for history.json (D26).
    """
    data["updated_at"] = datetime.now(MYT).isoformat()

    json_ok = write_to_json(data, LATEST_FILE)

    today = datetime.now(MYT).strftime("%Y-%m-%d")
    date_str = data["cpo"].get("date", today) if data.get("cpo") else today
    write_to_json(data, f"prices_{date_str}.json")
    write_history(ffb_days=ffb_days)

    return json_ok


def read_ffb_history() -> dict:
    """MPOB's daily prices already in history.json, as {date: {region: price}}.
    Empty if the file is missing, unreadable or from before D26."""
    try:
        entries = json.loads((JSON_DIR / HISTORY_FILE).read_text(encoding="utf-8")).get("ffb_days")
    except (OSError, ValueError, AttributeError):
        return {}
    days = {}
    for entry in entries if isinstance(entries, list) else []:
        if isinstance(entry, dict) and isinstance(entry.get("date"), str) and isinstance(entry.get("prices"), dict):
            days[entry["date"]] = entry["prices"]
    return days


def write_history(max_entries: int = HISTORY_ENTRIES, ffb_days: Optional[list] = None) -> bool:
    """Write history.json, oldest first, so the History tab needs one small request.

    - `days`: the daily CPO prices, from the prices_*.json files.
    - `ffb_days`: MPOB's daily price per 1% OER for each region (D26). The
      days already in the file are kept, and `ffb_days` (this run's read of
      MPOB's summary) are added. A day read again replaces the earlier copy,
      so a price MPOB adds or corrects later is picked up.
    """
    days = {}
    for path in JSON_DIR.glob("prices_*.json"):
        try:
            cpo = json.loads(path.read_text(encoding="utf-8")).get("cpo") or {}
        except (OSError, ValueError):
            continue
        if cpo.get("date") and cpo.get("price_myr_per_tonne"):
            days[cpo["date"]] = cpo["price_myr_per_tonne"]
    entries = [{"date": d, "cpo_price": days[d]} for d in sorted(days)][-max_entries:]

    ffb = read_ffb_history()
    for day in ffb_days or []:
        ffb[day["date"]] = day["prices"]
    ffb_entries = [{"date": d, "prices": ffb[d]} for d in sorted(ffb)][-max_entries:]

    return write_to_json(
        {
            "generated_at": datetime.now(MYT).isoformat(),
            "days": entries,
            "ffb_unit": "RM per tonne of FFB per 1% OER, at the mill gate",
            "ffb_source": "MPOB Daily FFB Reference Price (mill gate)",
            "ffb_days": ffb_entries,
        },
        HISTORY_FILE,
    )
