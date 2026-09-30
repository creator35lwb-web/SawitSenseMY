"""Live-site freshness watchdog for SawitSense.

Checks the *output* of the pipeline rather than whether its jobs ran: compares
the snapshot the public GitHub Pages site is serving with the newest snapshot
committed on main.

From 21 May to 30 Sep 2026 every scraper run reported success while the live
site kept serving 21 May data (bot commits never triggered the deploy). A
job-level check cannot see that failure; comparing outputs can.

Exit code 0 = live site is current, 1 = stale or unreachable (the workflow then
files an alert issue).

Author: SS (Claude Code), Sep 2026
"""

import json
import logging
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

import requests

logger = logging.getLogger(__name__)

LIVE_LATEST_URL = "https://creator35lwb-web.github.io/SawitSenseMY/data/latest.json"
REPO_LATEST_FILE = Path(__file__).parent.parent / "data" / "latest.json"

# Time allowed for the deploy to publish a new data commit before we alert.
DEPLOY_GRACE = timedelta(hours=2)
# Scrapes run twice per weekday; 4 days covers a long weekend plus GitHub's
# scheduling delays without false alarms.
MAX_DATA_AGE = timedelta(days=4)


def fetch_live_snapshot(url: str = LIVE_LATEST_URL, timeout: int = 30) -> dict:
    """Fetch the live latest.json, bypassing the Pages CDN cache."""
    resp = requests.get(
        url,
        params={"t": int(time.time())},
        headers={"Cache-Control": "no-cache"},
        timeout=timeout,
    )
    resp.raise_for_status()
    return resp.json()


def find_problems(live: dict, repo: dict, now: datetime) -> list:
    """Return human-readable problems; an empty list means the site is fresh."""
    problems = []
    repo_scraped_at = repo.get("scraped_at", "")
    live_scraped_at = live.get("scraped_at", "")
    try:
        repo_age = now - datetime.fromisoformat(repo_scraped_at)
    except (TypeError, ValueError):
        return [f"main's latest.json has an unreadable scraped_at: {repo_scraped_at!r}"]

    if live_scraped_at != repo_scraped_at and repo_age > DEPLOY_GRACE:
        problems.append(
            f"The live site is serving the snapshot scraped at {live_scraped_at}, "
            f"but main has a newer one ({repo_scraped_at}, "
            f"{repo_age.total_seconds() / 3600:.1f} hours old) that has not been deployed."
        )
    if repo_age > MAX_DATA_AGE:
        problems.append(
            f"The newest snapshot on main was scraped {repo_age.days} days ago "
            f"({repo_scraped_at}). The scraper may have stopped running."
        )
    return problems


def main() -> int:
    repo = json.loads(REPO_LATEST_FILE.read_text(encoding="utf-8"))
    try:
        live = fetch_live_snapshot()
    except (requests.RequestException, ValueError) as e:
        print(f"::error::Could not read the live snapshot at {LIVE_LATEST_URL}: {e}")
        return 1

    problems = find_problems(live, repo, datetime.now(timezone.utc))
    for problem in problems:
        print(f"::error::{problem}")
    if problems:
        return 1

    logger.info(f"Live site is current (snapshot scraped at {repo.get('scraped_at')}).")
    return 0


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
    sys.exit(main())
