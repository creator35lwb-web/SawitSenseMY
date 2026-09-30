# Handoff: SS (Claude Code) onboarding and first fixes

## Status: COMPLETED

> Closed by the next session: `20260930_SS_v0.3.1-decisions.md`.

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-09-30
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

Alton moved SawitSenseMY to Claude Code as its only development platform and paused QQ (Perplexity) after stopping that subscription. SS cloned the repo, reviewed the agent history and ran a health check. The last recorded handoff (handoff-003, 21 May) had never been closed.

The health check found the following. The evidence is in the PR descriptions and in `.macp/reasoning/20260930_SS_onboarding.md`.

- **Live site frozen for four months on 21 May data.** The scraper's bot commits use `GITHUB_TOKEN`, and those pushes never start `deploy_web.yml`.
- **History tab showing unlabelled synthetic prices since about 20 June.** This is a side effect of the frozen site.
- **No freshness badge** anywhere in the app.
- **Sarawak's indicative OER was actually Sabah's.** MPOB codes Sabah 13 and Sarawak 14; the scraper assumed 12 and 13.
- **No repo secrets are set, and one data push was silently lost** to an HTTP 500 on 29 Sep.
- **Out-of-date records:** attribution drift, the CHANGELOG and version, the README, and the ethical framework.

Where handoff-003 (21 May) now stands:

| Item | Status |
|------|--------|
| Attribution correction | Finished in #7 and #8. ADR-001 and four code headers still said "on behalf of CIO XV". |
| Sarawak overflow fix | Done in PR #4. |
| CHANGELOG and version bump | Done in #8 (0.3.0). |
| Telegram secrets | Still open (D5). |
| Track B | Still open (D6). |

---

## Pending Items

- [x] **Alton:** merge #6 first (it unfreezes the live site on merge), then #7, then #8. *(All three merged.)*
- [x] **SS:** after #6 merges, merge `main` into #7 so that CI runs on it. *(Overtaken: #7 was merged before this step. Tests on the merged `main` exposed a flaky test, which is fixed in #9.)*
- [x] **SS:** confirm the live site shows current data after #6 merges, using the watchdog and a manual check. *(Confirmed. A manual scrape also proved the full chain and put the Sarawak fix live.)*
- [x] **Alton:** decide D1–D7 in `PROJECT_STATUS.md`. *(Decided: "go with recommendation".)*
- [x] **SS:** open the frontend PR for the freshness badge and demo-data policy, after D1 and D2. *(#9)*
- [x] **SS:** open the ethical framework v1.1 PR, after D3. *(Folded into #9.)*

---

## Artifacts

| File | Location | Description |
|------|----------|-------------|
| PR #6 | https://github.com/creator35lwb-web/SawitSenseMY/pull/6 | Pipeline: deploy after each data commit, push retries, alerts, watchdog and PR checks |
| PR #7 | https://github.com/creator35lwb-web/SawitSenseMY/pull/7 | Sabah/Sarawak state codes, cross-check and data-quality warnings |
| PR #8 | https://github.com/creator35lwb-web/SawitSenseMY/pull/8 | SS registration and the project records brought up to date |
| `PROJECT_STATUS.md` | repo root | SSOT: status, known issues, decisions and backlog |
| `SS_Claude_Code_Genesis_Master_Prompt_v1.0.md` | repo root | SS's identity, role, rules and session protocol |
| `20260930_SS_onboarding.md` | `.macp/reasoning/` | Why each decision in this session was made |

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| Claude Code is the only development platform, and QQ (Perplexity) is paused | The Perplexity subscription has stopped, and the project is small and in maintenance | Alton |
| Claude Code works here as **SS**, with the role CTO & Lead Maintainer | Alton's choice. It continues the Phase 0 SS identity (Claude.ai) on a new platform | Alton |
| This public repo is the single source of truth, and secrets and personal data stay out of it | One place and nothing to sync; CI scans every PR for credentials | Alton |
| SS opens PRs and Alton merges them | Alton stays the human gate for everything smallholders see | Alton |
| From now on each handoff is its own Markdown file in `.macp/handoffs/`, and reasoning logs are added | Matches the MACP v2.2 layout and Alton's other projects; `handoffs.json` stays as the archive | Alton (on merge) |

---

## Blockers

None. Everything else is waiting on PR review.

---

## Notes

- Flutter isn't installed on Alton's machine, so frontend changes are verified in CI. CI on #6 passed `flutter analyze` with no issues and all 23 `flutter test` tests.
- Only the scraper bot writes to `backend/data/`. Don't edit those files by hand.
