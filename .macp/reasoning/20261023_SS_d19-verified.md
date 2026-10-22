# Reasoning Log: D19 verification, 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** post-merge verification
**Related:** handoff `.macp/handoffs/20261023_SS_d19-verified.md`, PRs #36 and #37, D19

## Decision: run the watchdog by hand right after the merge

- **Why:** the first scheduled run is three days away (Monday). A manual run proves today that the workflow works from `main`, not only from the PR branch.
- **What differs from the PR run:**
  - this one was a `workflow_dispatch` on `main`, the event the alert step is meant for;
  - on a pass that step must be skipped, and it was.
- **Why it's safe:** the check only reads OSV and opens an issue only on a problem. It writes nothing to the repo.

## Checking the schedule is registered

- GitHub registers a workflow's schedule only once the file is on the default branch.
- The workflows API lists "Vulnerability watchdog" as `active`.
- The next session confirms that the first Monday run actually fired.

## What wasn't verifiable this session

The alert path on a real hit (filing the `security-alert` issue) can't safely be triggered on `main` without faking a vulnerability. It is covered by:
- the Python tests of the report;
- the local Node run of the step's script with stand-ins (#36);
- the same `issues.create` pattern as the other workflows' alert steps. The scraper's filed a real issue, #33, which also created its label.
