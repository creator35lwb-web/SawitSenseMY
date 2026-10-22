# Handoff: MPOB's month start handled (K26, #44)

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-23
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.1

---

## Context

Alton merged #43. Everything was healthy, and MPOB's 23 Oct update is due around noon MYT.

Rather than wait for 1 November, SS asked MPOB's server about November and December now.
- **What MPOB returned:** HTTP 500 for both. That is not a 404, and not an empty table.
- **What the scraper did with that:** v0.4.0 took a 500 to mean "MPOB is down" and didn't fall back to October.
- **The effect on 1 Nov:** from 1 November until MPOB's first November price (1 Nov is a Sunday, so likely Monday noon), every run would have carried October's prices forward with a warning, and so raised a false alert (K26).

**#44:**
- **`backend/scrapers/mpob_ffb.py`:**
  - a 500 that persists through all 3 attempts counts as "no document for this month";
  - in a month's first 7 days, that falls back to last month's PDF;
  - later in the month it is an error, and raises an alert;
  - 503, a timeout or a refused connection still mean MPOB is down: no fallback (K23).
- **`backend/run_scraper.py`:** a read older than the official prices already shown never replaces them (K7). Without this, a passing 500 in early November could have put October's prices up in place of November's.
- **Tests:** 8 new; 185 backend tests pass, flake8 clean.
- **Checked against MPOB's real server:** "on 1 November", the scraper gets three 500s for November, then uses October's last prices (22 Oct) with no alert. "On 23 October" it is unchanged.
- **Records:** ADR-002, PROJECT_STATUS (K26), CHANGELOG [Unreleased].

---

## Pending Items

- [ ] **Alton:** merge #44.
- [ ] **SS, next session:** MPOB's 23 Oct prices go live after its noon update, with no warnings.
- [ ] **SS, 1–2 November:** confirm October's last prices stay up with no alert, then November's first price arrives.
- [ ] **SS:** the vulnerability watchdog's first scheduled run (Monday 26 Oct); October's OER (mid-November).

---

## Blockers

None.
