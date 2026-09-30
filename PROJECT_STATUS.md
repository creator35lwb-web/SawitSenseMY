# SawitSenseMY — Project Status

**The project's single source of truth for its current state.** Maintained by SS (Claude Code) and updated at the end of every working session.

**Last updated:** 30 September 2026 · SS (Claude Code)

---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | 0.3.0 (Path C recovery, May 2026); 0.3.1 in progress |
| Data mode | **Indicative.** MPOB's Daily FFB Reference Price has been behind a licensee login since May 2026 ([ADR-001](docs/ADR-001-mpob-data-source-change.md)). Regional prices are derived from the MPOC daily CPO price and MPOB's monthly OER. |
| Data pipeline | The scraper runs twice every weekday. Since 21 May, every run has succeeded; one update was lost to a failed push on 29 Sep. |
| Live site | **Stale: still serving 21 May 2026 data** until #6 merges. |
| Active agent | SS (Claude Code), the sole active agent. Alton merges every PR. |

---

## Open pull requests

| PR | What it fixes | Merge order |
|----|---------------|-------------|
| [#6](https://github.com/creator35lwb-web/SawitSenseMY/pull/6) | The live site frozen on 21 May data, silent push failures, and no deploy alerts. Also adds PR checks and a live-site watchdog. | 1st |
| [#7](https://github.com/creator35lwb-web/SawitSenseMY/pull/7) | Sarawak showing Sabah's OER. Also adds a cross-check against MPOB's totals and data-quality warnings. | 2nd |
| [#8](https://github.com/creator35lwb-web/SawitSenseMY/pull/8) | This file, SS registration, and the project records brought up to date. | 3rd |

---

## Known issues

| # | Severity | Issue | Status |
|---|----------|-------|--------|
| 1 | 🔴 | The live site serves 21 May data, because bot commits never triggered a deploy. | Fixed by #6 |
| 2 | 🔴 | The History tab shows synthetic prices, with no label, whenever real history can't load (`demoHistory()`). This has been happening since about 20 June. | #6 removes the cause; the fallback itself needs the frontend fix (D2) |
| 3 | 🔴 | The app shows no freshness badge, although the ethical framework requires one. | Frontend PR (D1) |
| 4 | 🟠 | Sarawak's indicative OER was actually Sabah's, overstating its indicative fair price by about RM 64/t. | Fixed by #7 |
| 5 | 🟠 | If loading fails, the Calculator fills in 2025 demo prices without a label. | Frontend PR (D2) |
| 6 | 🟠 | No repo secrets are set, so Telegram alerts, Firestore and the Commodities-API fallback have never been active. GitHub issues are the only alert channel. | D5 |
| 7 | 🟡 | When one source fails, `latest.json` is still overwritten, so the site can lose its prices until the next good run. From #7 on, this raises an alert. | Backlog |
| 8 | 🟡 | All six regional cards show the same indicative Price_1%, because it comes from a single national CPO price. The notice text also implies OER is part of that figure. | Backlog |

---

## Decisions waiting on Alton

| ID | Decision | SS recommendation |
|----|----------|-------------------|
| D1 | **Freshness badge thresholds.** The framework says GREEN under 6h, AMBER 6–12h, RED over 12h. Prices only change on trading days, so that rule shows RED every weekend and most mornings. | Keep the framework's rule for now, show the age in words ("Updated 2 days ago"), and revisit trading-day thresholds in framework v1.1. |
| D2 | **Demo data.** Remove synthetic prices from the app, or keep a clearly labelled demo mode? | Remove them. An honest "no data" state is safer than realistic fake prices. |
| D3 | **Ethical framework v1.1.** Record the Path C indicative exception approved on 21 May. The framework still says "only MPOB official formulas". | Yes, as its own small PR. |
| D4 | **Historical Sarawak figures.** `prices_*.json` from 21 May until #7 carry the wrong Sarawak OER. | Leave them as they are; the error is documented in ADR-001. |
| D5 | **Secrets.** Set up Telegram alerts? Retire Firestore, which has never been configured and isn't read by the app? | Retire Firestore. Telegram is optional, because the alert issues already @-mention Alton. |
| D6 | **Track B.** Register as an MPOB licensee to restore the authoritative price (ADR-001). | Open since May. No action without Alton. |
| D7 | **Issue #5** (Headline Arena, promotional). | Close it politely: forecasts aren't verified prices. |

---

## Backlog (after the open PRs)

1. Frontend honesty fixes: the freshness badge and the demo-data policy (D1, D2).
2. Keep the last good data when a source fails (known issue 7).
3. Cache the last known prices in the app. This is an architecture decision in AGENTS.md that hasn't been built yet.
4. Serve one `history.json` index instead of making 30 requests every time the History tab loads.
5. Explain the regional cards honestly while prices are indicative (known issue 8).
6. Add Chinese (CN), which the ethical framework requires.
7. Move the cron schedule off the half-hour, to reduce GitHub's 4–8 hour scheduling delays.

---

## Where things live

| Record | Location |
|--------|----------|
| Agent registry | [.macp/agents.json](.macp/agents.json) |
| Active agent's Genesis | [SS_Claude_Code_Genesis_Master_Prompt_v1.0.md](SS_Claude_Code_Genesis_Master_Prompt_v1.0.md) |
| Earlier Genesis docs | [QQ (Qoder)](QQ_Genesis_Master_Prompt_v1.0.md), [QQ (Perplexity)](QQ_Perplexity_Genesis_Master_Prompt_v1.0.md) |
| Handoffs | [.macp/handoffs/](.macp/handoffs/), one file each. Earlier ones (April–May 2026) are in [.macp/handoffs.json](.macp/handoffs.json) |
| Reasoning logs | [.macp/reasoning/](.macp/reasoning/) |
| Ethical framework | [.macp/ethical_framework.md](.macp/ethical_framework.md) |
| Architecture decisions | [docs/](docs/) |
| Release history | [CHANGELOG.md](CHANGELOG.md) |
