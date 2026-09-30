# Handoff: Session close, 30 Sep 2026: v0.3.4 live; next up D9 and D10

## Status: COMPLETED

> Picked up by the next session: `20260930_SS_v0.3.5-ui-polish.md`.

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-09-30 (session close)
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

This closes the first day of SS on Claude Code. Across the day, Alton merged PRs #6–#12, and SS verified each one on the live site.

| Version | What it did | PR |
|---|---|---|
| 0.3.0 → live fix | Unfroze the live site; dispatches the deploy after data commits; alerts; PR checks; locked dependencies | #6 |
| — | Sarawak showed Sabah's OER; now uses MPOB's state codes and is cross-checked | #7 |
| — | SS registered; the repo became the single source of truth | #8 |
| 0.3.1 | Freshness badge; no made-up prices; Firestore retired; ethical framework v1.1 | #9 |
| 0.3.2 | Every figure links to a public page where it can be checked; "How is this calculated?" | #10 |
| 0.3.3 | A failed source never replaces the last good data | #11 |
| 0.3.4 | History loads in one request; CI builds the web app; cron moved to `:13` | #12 |

**Since the last handoff** (`20260930_SS_v0.3.4-history-index.md`):
- #12 was merged at 09:18 UTC.
- SS ran scrape `#36695407003`; deploy `#36695456998` followed and succeeded.
- `history.json` is live with 60 entries, the bundle reads it, and the footer is v0.3.4.
- The merge's own deploy `#36695284529` shows *cancelled*. The newer deploy superseded it (the `pages` concurrency group), which is expected and raises no alert.
- Alton set D9 and D10 as next session's topics.

**Reasoning log:** skipped for this close. It only covered post-merge verification, with no judgment calls. The v0.3.4 session's decisions are in `.macp/reasoning/20260930_SS_v0.3.4-history-index.md`.

---

## Pending Items

- [ ] **Alton + SS, next session:** D9, offline-first scope. SS recommends deferring until users report connection problems. *(Carried forward.)*
- [ ] **Alton + SS, next session:** D10, Chinese (CN). SS drafts Simplified Chinese for the 70 strings; a native reader reviews. *(Carried forward: Alton asked for UI polish first.)*
- [ ] **SS, next session:** check that the first scheduled scrape on the `:13` cron (1 Oct, 00:13 UTC) started close to time. *(Carried forward: not yet due.)*
- [x] **Alton:** merge #13 (these records) whenever convenient. *(Merged 09:57 UTC.)*
- [ ] **Alton:** D6 (Track B), whenever convenient. It is not blocking. If Alton goes ahead, K10 (wiring the authoritative path) comes with it.

---

## Artifacts

| File | Location | Description |
|------|----------|-------------|
| `PROJECT_STATUS.md` | repo root | Current state, with a "Next session starts here" note |
| This handoff | `.macp/handoffs/` | The state for the next session |

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| D9 and D10 are next session's topics | Alton signed off for the day | Alton |

---

## Blockers

None. The site is live and current, alerts are in place, and there are no open issues.

---

## Notes for the next session

- **Start:** read `AGENTS.md`, `PROJECT_STATUS.md` and this handoff, then check open issues (`scraper-alert`, `deploy-alert`, `freshness-alert`) and open PRs.
- **Flutter isn't installed locally.** Check Dart changes with `gh workflow run ci.yml --ref <branch>` before opening a PR.
- **After any merge that changes the backend payload,** run the scraper once (`gh workflow run scraper_cron.yml`), so the live data carries the new fields straight away.
