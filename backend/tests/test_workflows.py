"""Checks on the GitHub workflows, so a failure can't go unnoticed.

Author: SS (Claude Code), Oct 2026
"""

from pathlib import Path

WORKFLOWS = Path(__file__).parent.parent.parent / ".github" / "workflows"


def test_scraper_alert_also_fires_when_a_run_runs_out_of_time():
    # A run that hits timeout-minutes is cancelled, not failed. On 21 Oct
    # 2026 one did, published nothing, and raised no alert (K23).
    workflow = (WORKFLOWS / "scraper_cron.yml").read_text(encoding="utf-8")
    alert_step = workflow.split("- name: Open alert issue on failure", 1)[1]
    assert "if: failure() || cancelled()" in alert_step.split("uses:", 1)[0]
