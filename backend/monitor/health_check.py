"""Scraper Health Monitor for SawitSense.

Tracks consecutive failures and sends alerts.
Designed to run after each scraper execution.

Author: QQ (Qoder CSO)
"""

import json
import logging
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

import requests

logger = logging.getLogger(__name__)

MYT = timezone(timedelta(hours=8))
HEALTH_FILE = Path(__file__).parent.parent / "data" / "health.json"
ALERT_THRESHOLD = 2  # Alert after 2 consecutive failures


def load_health_state() -> dict:
    """Load health state from disk."""
    try:
        if HEALTH_FILE.exists():
            with open(HEALTH_FILE, "r") as f:
                return json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
    return {"consecutive_failures": 0, "last_success": None, "last_failure": None, "total_runs": 0}


def save_health_state(state: dict) -> None:
    """Save health state to disk."""
    HEALTH_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(HEALTH_FILE, "w") as f:
        json.dump(state, f, indent=2)


def send_telegram_alert(message: str) -> bool:
    """Send alert via Telegram bot.

    Requires TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID env vars.
    """
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID")

    if not token or not chat_id:
        logger.warning("Telegram credentials not configured. Skipping alert.")
        return False

    try:
        resp = requests.post(
            f"https://api.telegram.org/bot{token}/sendMessage",
            json={"chat_id": chat_id, "text": message, "parse_mode": "Markdown"},
            timeout=10,
        )
        resp.raise_for_status()
        logger.info("Telegram alert sent")
        return True
    except requests.RequestException as e:
        logger.error(f"Telegram alert failed: {e}")
        return False


def report_success() -> dict:
    """Report successful scrape."""
    state = load_health_state()
    state["consecutive_failures"] = 0
    state["last_success"] = datetime.now(MYT).isoformat()
    state["total_runs"] = state.get("total_runs", 0) + 1
    save_health_state(state)
    logger.info("Health: scrape SUCCESS")
    return state


def report_failure(error_msg: str = "") -> dict:
    """Report failed scrape. Send alert if threshold reached."""
    state = load_health_state()
    state["consecutive_failures"] = state.get("consecutive_failures", 0) + 1
    state["last_failure"] = datetime.now(MYT).isoformat()
    state["last_error"] = error_msg
    state["total_runs"] = state.get("total_runs", 0) + 1
    save_health_state(state)

    if state["consecutive_failures"] >= ALERT_THRESHOLD:
        alert_msg = (
            f"*SawitSense Scraper Alert*\n"
            f"Consecutive failures: {state['consecutive_failures']}\n"
            f"Last error: {error_msg}\n"
            f"Last success: {state.get('last_success', 'Never')}\n"
            f"Action: Check MPOB BEPI portal or fallback API"
        )
        send_telegram_alert(alert_msg)
        logger.warning(f"Health: {state['consecutive_failures']} consecutive failures. Alert sent.")
    else:
        logger.warning(f"Health: scrape FAILED ({state['consecutive_failures']} consecutive)")

    return state


def get_data_freshness(last_success_iso: Optional[str] = None) -> dict:
    """Calculate data freshness indicator.

    GREEN: <6 hours since last success
    AMBER: 6-12 hours
    RED: >12 hours
    """
    if last_success_iso is None:
        state = load_health_state()
        last_success_iso = state.get("last_success")

    if not last_success_iso:
        return {"status": "RED", "hours_old": None, "message": "No data available"}

    try:
        last_success = datetime.fromisoformat(last_success_iso)
        now = datetime.now(MYT)
        delta_hours = (now - last_success).total_seconds() / 3600

        if delta_hours < 6:
            status = "GREEN"
        elif delta_hours < 12:
            status = "AMBER"
        else:
            status = "RED"

        return {
            "status": status,
            "hours_old": round(delta_hours, 1),
            "last_update": last_success_iso,
        }
    except (ValueError, TypeError):
        return {"status": "RED", "hours_old": None, "message": "Invalid timestamp"}
