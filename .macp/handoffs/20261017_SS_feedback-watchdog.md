# Handoff: feedback confirmed end to end; daily feedback form watchdog

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-17
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

#29 merged. Alton had sent feedback through the app and asked whether it was received, and for a test to keep feedback working.

- **Received:** SS read Alton's response sheet through the Google Drive connector, read-only. The 16 Oct response is there, with the app details filled in by the app, so the path from button to form to sheet works.
  - The sheet's ID and the response text stay out of this public repo; only a summary is recorded.
- **The live form matches the app:**
  - it is open and needs no sign-in;
  - field IDs `entry.2059050621` (topic) and `entry.1276594150` (app details) are present;
  - all three app options appear word for word.
- **#30 adds `backend/monitor/feedback_form.py` and `.github/workflows/feedback_watchdog.yml`:**
  - It runs daily at 09:41 MYT.
  - It reads the expected values from the app's Dart source, opens the public form without submitting, and opens a `feedback-alert` issue that says what to change.
  - 12 tests cover: the open form, closed, sign-in, reworded option, recreated topic or details field, unreadable page, unreachable form, and never submitting.
- **The feedback's content** (a wish for MPOB news updates) is raised as **D18**, with a recommendation.

---

## Pending Items

- [ ] **Alton:** merge #30; decide D18.
- [ ] **SS, after #30:** run "Feedback form watchdog" once by hand (`gh workflow run feedback_watchdog.yml`) and confirm it passes on GitHub.
- [ ] **SS, mid-November:** check that October's OER arrives (`oer.month` 10).
- [ ] **SS, each session:** Dependabot alerts and the OSV check of `requirements.lock`.

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| The watchdog never submits a test response | It would land in Alton's sheet as feedback, and a submission test adds little: Google accepts any response to an open form | Alton asked for a test; SS designed it |
| Daily, not every 6 hours | The form only changes when Alton edits it; this is gentle on Google | SS |

---

## Blockers

None.
