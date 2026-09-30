# Reasoning Log: SS (Claude Code) onboarding, 2026-09-30

**Agent:** SS (Claude Code) · **Session type:** onboarding and incident review
**Related:** handoff `.macp/handoffs/20260930_SS_onboarding-and-first-fixes.md`; PRs #6, #7, #8

This log records *why* each decision was made, including where the thinking changed along the way. The handoff records *what* was done.

---

## Decision 1: Which identity Claude Code uses in this project

- **Trigger:** After moving development to Claude Code, Alton asked which role to continue with.
- **Options considered:**
  1. **RNA**, Claude Code's identity in Alton's other YSenseAI projects.
  2. **QQ (Claude Code)**, a new member of the QQ family, continuing Qoder → Perplexity.
  3. **SS**, the identity of the Phase 0 designer on Claude.ai.
- **What SS first recommended: RNA**, titled "Lead Developer & SSOT Steward". The reasons were:
  - MACP v2.2's Identity Clarity principle: one agent, one ID.
  - Alton's `/macp-inbox` and `/session-close` commands already key on RNA.
  - The title "CSO" should be avoided. Here it means Chief *Strategy* Officer; in FLYWHEEL it means Chief *Security* Officer.
- **Chosen: SS**, by Alton.
  - SawitSense's Phase 0 designer was already a Claude agent (SS on Claude.ai). Carrying SS over to Claude Code follows the "same identity, new platform" lineage this project already used when QQ moved from Qoder to Perplexity.
  - It keeps SawitSenseMY separate from RNA's work on Alton's other projects, which the project's session-isolation rule asks for.
- **Rejected: QQ (Claude Code).** A third QQ platform would blur the one clear boundary in the registry: QQ were the April–May builders and executors.
- **Consequence handled:** `agents.json` and the SS Genesis both state that Claude Code is RNA elsewhere and SS here, and that neither signs for the other.
- **Confidence:** high. It is Alton's call, and it is consistent with the project's history.

## Decision 2: Where the single source of truth lives

- **Options:**
  - This public repo.
  - A private `SawitSenseMY-ops` repo, as MarketPulse uses.
- **Chosen:** this public repo (Alton's decision), with a hard rule that secrets and personal data stay out of it.
- **Why:** SawitSense is an open-source, public-good tool with no private operational data. A second repo would need syncing, which is exactly how records drift.
- **Guardrails added:**
  - A credential scan in CI, with a self-test, because a scan that has never fired proves nothing.
  - `.gitignore` rules for credential files.
  - A list in the Genesis of what never goes in the repo.

## Decision 3: How bot data commits reach the live site (#6)

- **Root cause:** GitHub never starts workflows from `GITHUB_TOKEN` pushes (except `workflow_dispatch` and `repository_dispatch`). So the `backend/data/**` trigger in `deploy_web.yml` could never fire for bot commits. Deploys happened only on human pushes (12 Apr and 21 May).
- **Options:**
  - (a) The scraper dispatches the deploy after it commits.
  - (b) A `workflow_run` trigger on the scraper.
  - (c) Build and deploy inside the scraper workflow.
  - (d) The app reads data from raw.githubusercontent.com, so data changes need no deploy.
- **Chosen: (a).** It deploys only when data actually changed, keeps a single deploy path, and uses the documented exception.
- **Rejected:**
  - (b) deploys after every run, including failed ones.
  - (c) doubles the Flutter builds and mixes two jobs together.
  - (d) is a frontend change that can't ship without a working deploy anyway. Worth revisiting later.
- **Forecast, to check next session:**
  - Merging #6 redeploys straight away, because the workflow file is included in its own path filter.
  - The live site then shows 28/29 Sep data within about 5 minutes.
  - The watchdog passes on its first scheduled run.

## Decision 4: What to do when OER figures don't reconcile (#7)

- **Options:**
  - (a) Fail closed and stop publishing.
  - (b) Fall back to MPOB's own published Sabah, Sarawak and Peninsular totals, and raise an alert.
  - (c) Log it only.
- **Chosen: (b).** MPOB's totals are official figures, so the fallback is correct data, just less detailed.
- **Rejected:**
  - (a) would freeze the site again.
  - (c) is the silent decay this project has already paid for twice.
- **Alerting design:** the payload carries a `warnings` list. A workflow step fails *after* the deploy has been dispatched, so the alert fires without blocking fresh data.

---

## Mistakes caught mid-session

| Thought | Caught when | Corrected to | Lesson |
|---------|-------------|--------------|--------|
| "None of the 186 data commits reached users." | Before sending: data committed before 21 May *was* bundled into the 21 May deploy. | "No data update since 21 May has reached the site." | Check where a count starts and ends before quoting it. |
| Watchdog message: "main has had a newer one for 21.4 hours." | Running it against the real site: it reads as "one day behind", when the site was four months behind. | "main has a newer one (…, 21.4 hours old) that has not been deployed." | Test alert wording against the real incident, not only in unit tests. |
| "All green tests mean the OER mapping is right." | Checking the live API: the tests asserted the same wrong codes the scraper used. | Tests now use a fixture recorded from the live API, plus a runtime cross-check against MPOB's totals. | Test against recorded reality, not against the author's assumptions. |

---

## Open questions

Decisions D1–D7 in `PROJECT_STATUS.md`.

## Closing assessment

- **What I'd redo:** check the live site's output before reading any code. One HTTP request would have shown the freeze.
- **What the next SS session inherits cleanly:**
  - CI on every PR.
  - Alerts for the scraper, the deploy and live-site freshness.
  - A status file that says what is true.
- **What the next SS session will probably struggle with:**
  - Flutter isn't installed locally, so every frontend change goes through CI.
  - The indicative-price method in ADR-001 stays a judgment call until Track B is decided.
