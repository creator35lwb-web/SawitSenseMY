# Handoff: health check 22 Oct; certifi advisory; scraper resilience (K22, K23)

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-22
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

Routine "Activate SS". #32 had merged. Found three things:

1. **Issue #33, 22 Oct 11:43 UTC (K22).**
   - MPOC answered with a page without its price table. With no CPO price, the run stopped; the last good prices stayed live (K7) and the alert fired.
   - By 14:38 UTC the page read normally, with the same layout, so this was transient.
   - **Gap:** the scraper retried only network errors, not a "200 but wrong page" answer, and logged nothing about what the page was.
2. **A silent cancelled run, 21 Oct 07:31 UTC (K23).**
   - MPOB's servers (bepi and prestasisawit) stopped answering. Each request waited about 60 s (30 s connect, apparently per address).
   - The legacy BEPI attempt took 2 min, then the OER lookup tried 3 months × 3 attempts, and the job hit `timeout-minutes: 10`.
   - **Result:** MPOC's fresh price wasn't published, and the alert step (`if: failure()`) was skipped, because a timeout is *cancelled*. Prices went RED for 68 min.
3. **`certifi` 2026.7.22 is affected by GHSA-6q48-6c7w-9gw2** (critical, published 20 Oct). Found by the OSV check; Dependabot can't see transitive packages in the hash-locked file (D17).

**PRs:**
- **#34** bumps `certifi` to 2026.10.19. Both hashes come from PyPI, the wheel was downloaded and its SHA-256 verified, and OSV is clean after the bump.
- **#35** carries the scraper fixes and the records, and closes #33:
  - **OER:** stops after the first month when the API doesn't answer; connect timeout 10 s.
  - **Legacy BEPI:** timeout 10 s, passed in from `run_scraper.py`, so the math layer is untouched.
  - **Workflow:** the alert also fires on `cancelled()`.
  - **MPOC:** fetches the page again after a pause (30 s, up to 2 more times) when the table is missing. A final miss logs the size, table count and kind of page, never its text.
  - **Tests:** 9 new; 119 backend tests pass. The patched scrapers ran live: MPOC 0.7 s, OER 0.5 s, same figures.

**GitHub Actions was degraded on 22 Oct** (an incident from 14:18 UTC). SS's manual scraper run (39797860528) was queued behind it.

**D19 raised:** a weekly automatic OSV check of `requirements.lock`, opening a `security-alert` issue. SS recommends yes.

---

## Pending Items

- [ ] **Alton:** merge #34 first, then #35; decide D19.
- [ ] **SS, after the merges:** a scraper run succeeds with `certifi` 2026.10.19, and #33 is closed (#35 has "Closes #33").
- [ ] **SS:** confirm that manual run 39797860528 (or the next scheduled run) refreshed the prices once Actions recovered.
- [ ] **SS, mid-November:** October's OER; check `oer.month` 10 and `in_app_since`.

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| Two PRs: the security bump alone, then the scraper fixes plus records | The security fix can land first and is easy to review on its own | SS |
| Don't close #33 by hand; let #35 close it on merge | No precedent for SS closing alert issues; Alton's merge closes it with the fix | SS |
| Log the kind of page MPOC served, never its text | Logging page text would let a page forge log lines (the class of K16) | SS |

---

## Blockers

GitHub Actions degraded (external). Nothing on SawitSense's side.
