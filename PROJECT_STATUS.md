# SawitSenseMY — Project Status

**This file is the single source of truth for the project's current state.** SS (Claude Code) maintains it and updates it at the end of every working session.

**Last updated:** 30 September 2026 (second session) · SS (Claude Code)

---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | 0.3.1 in [#9](https://github.com/creator35lwb-web/SawitSenseMY/pull/9); 0.3.0 is live until #9 merges |
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

---

## Open pull requests

| PR | What it does |
|----|--------------|
| [#9](https://github.com/creator35lwb-web/SawitSenseMY/pull/9) | v0.3.1: freshness badge (D1), no made-up prices (D2), ethical framework v1.1 (D3), Firestore retired (D5), a flaky test fixed, and these records |

---

## Open issues

| ID | Severity | Issue | Next step |
|---|----------|-------|-----------|
| K7 | 🟡 | When one source fails, `latest.json` is still overwritten, so the site can lose its prices until the next good run. Since #7 this raises an alert. | Keep the last good values per source (backlog item 1) |
| K8 | 🟡 | All six regional cards show the same indicative Price_1%, because it comes from one national CPO price. The banner implies OER is part of that figure. | Explain the regional cards honestly (backlog item 4) |

### Fixed on 30 Sep 2026

| ID | Issue | Fixed by |
|---|-------|----------|
| K1 | Live site served 21 May data for four months | #6 |
| K2 | History tab showed synthetic prices with no label | #6 (cause), #9 (demo data removed) |
| K3 | No freshness badge anywhere in the app | #9 |
| K4 | Sarawak's indicative OER was actually Sabah's | #7 |
| K5 | Calculator auto-filled 2025 demo prices without a label | #9 |
| K6 | Firestore and Telegram configured but never active | #9 retires Firestore; Telegram stays off by choice (D5) |
| K9 | `test_no_data` only passed while the data was stale | #9 |

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

---

## Backlog

1. Keep the last good data per source when a source fails (K7).
2. Cache the last known prices in the app. This is an AGENTS.md architecture decision that hasn't been built yet.
3. Serve one `history.json` index instead of 30 requests every time History loads.
4. Explain the regional cards honestly while prices are indicative (K8).
5. Chinese (CN) language, which the ethical framework requires.
6. Move the cron schedule off the half-hour to reduce GitHub's 4–8 hour scheduling delays.
7. Optional housekeeping: delete merged branches on GitHub, or turn on "Automatically delete head branches".

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
