# Handoff: MPOC's bot-check page named in the scraper log (#43)

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-23
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.1

---

## Context

Alton merged #42.
- **State at the start:** all healthy. No issues, PRs or alerts; OSV clean. The live data is MPOB's official 22 Oct prices, OFFICIAL, with no warnings. MPOB's 23 Oct update is due around noon MYT.
- **The follow-up:** the open one from 23 Oct (handoff `20261023_SS_estimate-vs-mpob.md`). MPOC served SS's machine a page reading "Please wait while your request is being verified". The scraper on GitHub still gets the prices, but if that page ever reached the runners, the log would say only "0 tables".

**#43:**
- `_PAGE_HINTS` in `backend/scrapers/mpoc_cpo.py` gains "request is being verified" → "a bot check". A label is named once even when two signs match.
- **Tests:** two new; 177 backend tests pass, flake8 clean.
- **Checked against the real page saved on 23 Oct:** it is described as "12015 bytes, 0 tables, looks like a bot check".
- The page's text is still never logged.

---

## Pending Items

- [ ] **Alton:** merge #43.
- [ ] **SS, next sessions:**
  - after MPOB's noon update, the live `ffb.date` should move to 23 Oct with no warnings;
  - on 1 November, October's last prices should be kept without an alert.
- [ ] **SS:** the first scheduled vulnerability watchdog run (Monday 26 Oct); October's OER (mid-November).
- [ ] **Alton (optional):**
  - a native reader's check of the new BM and 中文 wording;
  - telling MPOB;
  - the verdict thresholds.

---

## Blockers

None.
