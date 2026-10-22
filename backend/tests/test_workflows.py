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


def test_vulnerability_alert_fires_on_a_scheduled_run_but_not_on_a_pull_request():
    # D19: a hit in the weekly check files an alert issue, also when the run
    # runs out of time (K23). On a pull request the failed check is the alert.
    workflow = (WORKFLOWS / "vulnerability_watchdog.yml").read_text(encoding="utf-8")
    alert_step = workflow.split("- name: Open alert issue on a known vulnerability", 1)[1]
    condition = "if: (failure() || cancelled()) && github.event_name != 'pull_request'"
    assert condition in alert_step.split("uses:", 1)[0]
    # The check writes its findings where the alert step reads them.
    assert workflow.count("VULN_REPORT: ${{ runner.temp }}/vulnerabilities.md") == 2


def test_a_change_to_the_pinned_versions_is_checked_before_it_merges():
    workflow = (WORKFLOWS / "vulnerability_watchdog.yml").read_text(encoding="utf-8")
    pull_request = workflow.split("pull_request:", 1)[1].split("workflow_dispatch:", 1)[0]
    assert "- 'backend/requirements.lock'" in pull_request
