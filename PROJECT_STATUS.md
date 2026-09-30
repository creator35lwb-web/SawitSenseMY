# SawitSenseMY — Project Status

**This file is the single source of truth for the project's current state.** SS (Claude Code) maintains it and updates it at the end of every working session.

**Last updated:** 30 September 2026 (UI polish session) · SS (Claude Code)

> **Next session starts here:**
> 1. Read the newest handoff, `.macp/handoffs/20260930_SS_v0.3.5-ui-polish.md`.
> 2. Discuss D9 (offline-first scope) and D10 (Chinese) with Alton.
> 3. Check that the first scheduled scrape on the new `:13` cron (1 Oct, 00:13 UTC) started close to time.

---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | **0.3.4 live**; 0.3.5 in [#14](https://github.com/creator35lwb-web/SawitSenseMY/pull/14) (launch screen, logo, chart) |
| Data mode | **Indicative.** Since May 2026 MPOB's Daily FFB Reference Price has been behind a licensee login ([ADR-001](docs/ADR-001-mpob-data-source-change.md)). Regional prices are derived from the MPOC daily CPO price and MPOB's monthly OER. |
| Live site freshness | **Current.** Unfrozen on 30 Sep 2026 and checked by the freshness watchdog twice every weekday. |
| Data pipeline | The scraper runs twice every weekday and dispatches a deploy after each data commit. Supply chain: 17 hash-locked packages, wheels only. |
| Active agent | SS (Claude Code), the sole active agent. Alton merges every PR. |

### Verified in production on 30 Sep 2026
- The live `latest.json` matches `main`: the snapshot scraped at 15:09 MYT.
- A manual scraper run went green end to end. It covered the hash-locked install, the fixed OER mapping, the data-quality check (no warnings), and the **first bot-dispatched deploy**.
- Sarawak is live at **19.58% / RM 849.38 per tonne**, down from 21.06% / RM 913.58.
- The freshness watchdog passed with "Live site is current".
- MPOC's latest settlement is dated 28 Sep. MPOC publishes a day or two late; this is not a scraper fault.
- **v0.3.1 is live, checked after #9 merged.** The footer reads v0.3.1, the freshness badge shows in EN and BM, the honest unavailable state is present, and no demo data or old disclaimer remains in the app bundle.
- **v0.3.2 is live, checked after #10 merged.**
  - A manual scrape put the new fields in the live data.
  - Redoing the published sum from the live figures gives exactly the published price: RM 4664.00 × 0.01 × 0.93 = RM 43.38.
  - The footer reads v0.3.2, and the method sheet's text is present in EN and BM.
  - All four links the app shows return HTTP 200: MPOC, MPOB OER, ADR-001, and open data.
- **v0.3.3 is live, checked after #11 merged.** A manual run of the new code passed every step, and so did its deploy. The live data matches `main` with no warnings, the OER is fresh (not carried forward), and the footer reads v0.3.3.
- **v0.3.4 is live, checked after #12 merged.**
  - Scraper run `#36695407003` and its deploy `#36695456998` both succeeded.
  - `history.json` is live with 60 entries (26 Jun → 28 Sep), the app bundle reads it, and the footer reads v0.3.4.
  - The merge-triggered deploy `#36695284529` shows *cancelled*. This is expected: a newer deploy that included the same code superseded it, and a cancellation doesn't raise an alert.

---

## Open pull requests

| PR | What it does |
|----|--------------|
| [#14](https://github.com/creator35lwb-web/SawitSenseMY/pull/14) | v0.3.5 UI polish: a launch screen instead of a blank page, a top-bar logo that fits, right-sized icons, and a history chart whose labels don't collide. Previewed at phone sizes before merge |

---

## Open issues

| ID | Severity | Issue | Next step |
|---|----------|-------|-----------|
| K10 | 🟡 | If MPOB's BEPI ever serves data again, `run_scraper` logs it but still publishes indicative values; the authoritative path isn't wired up | Part of Track B (D6). Only needed if Alton goes ahead |

### Fixed on 30 Sep 2026

| ID | Issue | Fixed by |
|---|-------|----------|
| K1 | Live site served 21 May data for four months | #6 |
| K2 | History tab showed synthetic prices with no label | #6 (cause), #9 (demo data removed) |
| K3 | No freshness badge anywhere in the app | #9 |
| K4 | Sarawak's indicative OER was actually Sabah's | #7 |
| K5 | Calculator auto-filled 2025 demo prices without a label | #9 |
| K6 | Firestore and Telegram configured but never active | #9 retires Firestore; Telegram stays off by choice (D5) |
| K7 | A failed source overwrote `latest.json`, so the site could lose its prices | #11 |
| K8 | Six regional cards showed the same price per 1% OER with no explanation | #10 ("How is this calculated?") |
| K9 | `test_no_data` only passed while the data was stale | #9 |
| K11 | A blank white page while the app loads, and a 2.7 MB logo shown as a ~40 px white square (also used as favicon and PWA icons) | #14 |
| K12 | History chart labels collided ("5009" over "5000", "09-25" over "09-28"), and the curve overshot real prices | #14 |

---

## Decisions (Alton, 30 Sep 2026)

| ID | Decision | Status |
|----|----------|--------|
| D1 | Keep the framework's freshness thresholds, and show the age in words and the exact time | Done in #9 |
| D2 | Remove demo prices from the app; show an honest "unavailable" state instead | Done in #9 |
| D3 | Ethical framework v1.1 records the Path C exception | Done in #9 |
| D4 | Leave historical `prices_*.json` as they are. The Sarawak error is documented in ADR-001 | Done (no change) |
| D5 | Retire Firestore. Telegram is optional and stays off; alert issues @-mention Alton | Done in #9 |
| D6 | Track B: MPOB licensee registration to restore the authoritative price | **Open. Alton's call**; SS takes no action without it |
| D7 | Close issue #5 (Headline Arena, promotional) | Done: closed with a courteous reply |
| D8 | Link every figure to a public page where it can be checked (small version, no over-engineering) | Done in #10 (verified live) |
| D9 | **Offline-first scope.** Caching prices on the phone only helps once the app itself has loaded. True offline use needs a service worker that caches the app, plus a new storage package. Adding a package needs Flutter to regenerate `pubspec.lock`: either installed on Alton's machine, or through a CI job that SonarCloud would flag for review | **Next session** (Alton, 30 Sep). SS recommends deferring until smallholders report connection problems; #11 and #12 already cover most of the need |
| D10 | **Chinese (CN)**, which ethical framework v1.1 requires | **Next session** (Alton, 30 Sep). SS can draft Simplified Chinese for the 70 strings, for a native reader to review |

---

## Backlog

1. Chinese (CN) language (D10).
2. Offline-first: cache prices and the app shell (D9, deferred by recommendation).
3. Optional housekeeping: delete merged branches on GitHub, or turn on "Automatically delete head branches".

---

## Previewing UI changes

Flutter isn't installed on Alton's machine, so every PR's CI uploads its web build as the **`web-preview`** artifact (kept 3 days). To see a change before merging:

1. Download it: `gh run download <run-id> -n web-preview`.
2. Serve it under `/SawitSenseMY/` to match the base href.
3. Open it at phone width (412 and 360 px) with mobile emulation.

Headless Chrome's plain `--window-size` is clamped to about 500 px wide on Windows, so use device emulation instead (e.g. puppeteer's `setViewport` with `isMobile`).

---

## Where things live

| Record | Location |
|--------|----------|
| Agent registry | [.macp/agents.json](.macp/agents.json) |
| Active agent's Genesis | [SS_Claude_Code_Genesis_Master_Prompt_v1.0.md](SS_Claude_Code_Genesis_Master_Prompt_v1.0.md) |
| Earlier Genesis docs | [QQ (Qoder)](QQ_Genesis_Master_Prompt_v1.0.md), [QQ (Perplexity)](QQ_Perplexity_Genesis_Master_Prompt_v1.0.md) |
| Handoffs | [.macp/handoffs/](.macp/handoffs/), one file each; April–May 2026 are in [.macp/handoffs.json](.macp/handoffs.json) |
| Reasoning logs | [.macp/reasoning/](.macp/reasoning/) |
| Ethical framework | [.macp/ethical_framework.md](.macp/ethical_framework.md) (v1.1) |
| Architecture decisions | [docs/](docs/) |
| Release history | [CHANGELOG.md](CHANGELOG.md) |
