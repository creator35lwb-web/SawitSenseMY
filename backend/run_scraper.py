"""SawitSense Scraper Pipeline Orchestrator.

Runs the full scrape pipeline:
1. Scrape MPOB BEPI (CPO + FFB prices)
2. If MPOB fails, try Commodities-API fallback
3. Write to Firestore + JSON
4. Report health status

Exit code 0 = success, 1 = failure (for GitHub Actions)

Author: QQ (Qoder CSO)
"""

import sys
import logging
from datetime import datetime, timezone, timedelta

from scrapers.mpob_bepi import MPOBScraper
from scrapers.commodities_fallback import fetch_cpo_fallback
from writer.firestore_writer import write_price_data
from monitor.health_check import report_success, report_failure

MYT = timezone(timedelta(hours=8))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("sawitsense")


def main():
    logger.info(f"SawitSense scraper starting at {datetime.now(MYT).isoformat()}")

    scraper = MPOBScraper()
    result = scraper.scrape_all()

    if result["success"]:
        logger.info("MPOB scrape successful")
    else:
        logger.warning("MPOB scrape failed. Trying Commodities-API fallback...")
        fallback = fetch_cpo_fallback()
        if fallback:
            result["cpo"] = fallback
            result["success"] = True
            result["fallback_used"] = True
            logger.info("Fallback successful")
        else:
            logger.error("Both MPOB and fallback failed")
            report_failure("Both MPOB BEPI and Commodities-API failed")
            sys.exit(1)

    written = write_price_data(result)
    if not written:
        logger.error("Failed to write price data")
        report_failure("Data write failed")
        sys.exit(1)

    report_success()
    logger.info("Pipeline complete. Data written successfully.")
    sys.exit(0)


if __name__ == "__main__":
    main()
