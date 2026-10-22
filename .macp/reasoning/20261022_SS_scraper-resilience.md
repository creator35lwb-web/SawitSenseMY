# Reasoning Log: scraper resilience and the certifi advisory, 2026-10-22

**Agent:** SS (Claude Code) · **Session type:** incident diagnosis, fix, security
**Related:** handoff `.macp/handoffs/20261022_SS_scraper-resilience.md`, issue #33, PRs #34 and #35, D19

## Diagnosis before patching

**#33 (11:43 UTC): `MPOC: settlement-price table not found on page`.**
- Running the same parser locally at 14:38 UTC read 10 rows, the latest being 21 Oct at RM 4,767.
- So the page layout hadn't changed; MPOC had briefly served a different page.

**The cancelled run (21 Oct).** The log showed:
- BEPI timing out after 60 s per endpoint;
- MPOC fine (4 s);
- then OER attempts 1–3 for September and 1–3 for August, about 60 s each, until the 10-minute cancel.

**Why it was silent:** in the jobs API, the `always()` commit step ran, but the `failure()` alert step was skipped.

## Fix choices

**OER: stop the month back-off only when the request itself fails.**
- `fetch` now returns `{}` for a JSON null, so an unpublished month still falls back to the month before.
- `None` now means "the server failed", and the search stops there.

**Connect timeout: 10 s.** A healthy server connects in well under a second. The read timeout stays at 30 s.

**BEPI: a 10 s timeout, passed from `run_scraper.py`.** AGENTS.md says not to refactor `mpob_bepi.py`, and the class already takes `timeout`.

**Worst case if MPOB is down: about 2 min.** That's BEPI 2 × ~20 s, plus OER 3 × ~20 s, plus MPOC a few seconds.

**MPOC: fetch again after 30 s, up to twice.** The worst case adds 1 min, and the total stays far inside 10 min.

**Logging the bad page: size, table count, and hints.** The hints are CloudFront, captcha or maintenance, matched as fixed strings. The page's own text, title included, is never logged: it is external content (the K16 log-injection class).

## Why measure freshness from latest.json commits only

- A failed run still commits `health.json` with the same "data: update prices" message.
- Counting those commits would overstate freshness, so the 22 Oct numbers use only commits that changed `latest.json`.
- Earlier checks are unaffected: 9–17 Oct had no failed runs.

## certifi

- **How it was found:** the OSV batch check of the lock file flagged GHSA-6q48-6c7w-9gw2, a compromised emSign intermediate CA.
- **How the fix was made:** `uv` isn't installed here. The entry was edited by hand with the version and its two PyPI hashes, the wheel's hash was verified with `pip download --require-hashes`, and CI installs the full lock on Linux.
- **Why D19:** an automatic weekly check would catch the next one without waiting for a session.

## Mistakes caught mid-session

| Thought | Caught when | Corrected to | Lesson |
|---------|-------------|--------------|--------|
| Freshness from all "data: update prices" commits | The 11:44 commit only touched `health.json` | Count only commits that changed `latest.json` | Measure the thing the reader sees. |
| A heredoc can carry the lock file's line-ending backslashes | The match failed; the backslashes had vanished | Build them with `chr(92)` | Same trap as before; escapes go through code. |
