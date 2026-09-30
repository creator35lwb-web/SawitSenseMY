# Handoff: v0.3.3: a failed source never replaces the last good data

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-09-30 (fourth session)
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

Alton merged #10. SS finished that PR's post-merge steps:
- Ran one scrape.
- Checked v0.3.2 on the live site. The sum reproduces exactly, and all four links return HTTP 200.

SS then took backlog item 1 (K7) under the Genesis mandate to work the prioritised backlog. **#11**:

| Case | Before | Now |
|------|--------|-----|
| MPOC fails (no CPO price) | Published a snapshot with no prices; the site lost them | Publishes nothing. The last good snapshot stays live, the freshness badge ages, and the alert fires |
| MPOB OER fails | Regional OER dropped | Previous month's OER carried forward (`carried_forward: true`), with a warning and alert |
| Everything fails | A `success: false` marker overwrote the good data | Publishes nothing; the last good snapshot stays live; alert |
| Everything works | — | Output identical to before, verified against the live scrapers |

**Found along the way (K10):** when legacy MPOB BEPI returned data, the log said "reverting to authoritative path", but that path doesn't exist. The log now tells the truth. Wiring the authoritative path belongs to Track B (D6).

---

## Pending Items

- [ ] **Alton:** review and merge #11. Merging deploys v0.3.3 (a footer version change); the data behaviour applies from the next scrape.
- [ ] **SS:** after the merge, confirm the next scheduled scrape is green and the live site matches `main`.
- [ ] **Alton:** D6 (Track B), whenever convenient. It is not blocking. If you go ahead, K10 comes with it.
- [ ] **SS, next:** backlog item 1: cache the last known prices in the app (offline-first).

---

## Artifacts

| File | Location | Description |
|------|----------|-------------|
| PR #11 | https://github.com/creator35lwb-web/SawitSenseMY/pull/11 | v0.3.3 |
| `decide_payload()` | `backend/run_scraper.py` | The rule, in one testable function |
| `read_latest()` | `backend/writer/json_writer.py` | Reads the last published snapshot |

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| With no CPO price, publish nothing rather than a partial or carried-forward snapshot | Carrying the CPO forward under a new `scraped_at` would make the freshness badge claim fresh data. Keeping the file untouched lets the badge age honestly. | SS (delegated) |
| A missing OER is carried forward, marked, and alerted | MPOB publishes monthly, so the previous figures are still the latest. Dropping them would lose the regional detail for no gain. | SS (delegated) |
| A run without a CPO price fails (exit 1) | A missing primary source needs a human to look; the deploy step is skipped | SS (delegated) |

---

## Blockers

None.
