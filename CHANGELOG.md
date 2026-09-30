# Changelog

All notable changes to SawitSense MY will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.1] - 2026-09-30

First release by SS (Claude Code). It makes the live site current, correct and honest about its data.

### Fixed
- Live site frozen on 21 May 2026 data: the scraper now dispatches the deploy after each data commit (#6)
- Failed data pushes are retried, then alert, instead of being dropped silently (#6)
- Sarawak's indicative OER was Sabah's: MPOB's state codes are 13 (Sabah) and 14 (Sarawak) (#7)
- The app no longer shows made-up prices when real data can't load. The History tab had been showing a synthetic series with no label (#9)
- A backend test that only passed while data was stale (#9)

### Added
- Data freshness badge on Dashboard and Calculator: GREEN/AMBER/RED with the age in words and the exact time (#9)
- Honest "prices can't be loaded" state with Try again; the Calculator asks for Price_1% instead of auto-filling (#9)
- Pull-request CI: backend tests + lint, Flutter analyze + tests, credential scan (#6)
- Deploy-failure alerts and a live-site freshness watchdog (#6)
- OER cross-check against MPOB's published totals, and a `warnings` list in the data payload (#7)
- `PROJECT_STATUS.md`, SS (Claude Code) Genesis, per-file handoffs and reasoning logs in `.macp/` (#8)
- Ethical framework v1.1: the Path C exception is recorded, and demo prices are banned (#9)

### Removed
- Firestore: never configured and never read by the app. Dependencies go from 46 to 17 hash-locked packages (#9)
- Demo data (`demoSnapshot`, `demoHistory`) (#9)

### Changed
- Footer disclaimer no longer says prices come from MPOB BEPI (#9)

## [0.3.0] - 2026-05-21

Path C recovery after MPOB moved the Daily FFB Reference Price behind a licensee login (see ADR-001). Built by QQ (Perplexity).

### Changed
- Data sources: MPOC daily CPO settlement and MPOB Prestasi Sawit monthly OER replace the MPOB BEPI scraper (#1)
- Regional Price_1% is now an **indicative** value (`CPO × 0.01 × 0.93`), labelled `is_indicative: true` (#1)

### Added
- Indicative-mode banner on Dashboard and Calculator, and an indicative chip on each region card, in EN and BM (#3)
- Auto-filed GitHub issue when a scheduled scrape fails (#1)
- ADR-001 and the QQ (Perplexity) Genesis Master Prompt v1.0 (#1, #2)

### Fixed
- Sarawak region card hidden behind the bottom navigation bar (#4)
- Attribution: Alton is the project's sole Human Orchestrator (#4)

## [0.2.1] - 2026-04-12

### Added
- SawitSense MY logo (palm frond + FFB + chart arrow) in Dashboard AppBar, browser favicon, PWA icon, OG share image, and README
- App version display in footer across all screens
- Social links: GitHub repo, X (@creator35lwb), LinkedIn (altonlee92)
- Visitor can report issues or give feedback via X DM or GitHub

### Fixed
- Deploy workflow now triggers on `backend/data/**` changes so real MPOB data auto-publishes to live site
- Flutter SDK version in CI matched to 3.41.6 (was 3.22.0, causing build failures)

## [0.2.0] - 2026-04-12

### Added
- **M1: Daily Price Dashboard** — CPO spot price card + 6 regional FFB Reference Prices (North, South, Central, East Coast, Sabah, Sarawak)
- **M2: Fair Price Calculator** — 3-input model (Region, OER%, optional Paid Price), GREEN/AMBER/RED verdict
- **M4: Price History Chart** — 30-day CPO spot price line chart (fl_chart)
- **BM/EN Language Toggle** — full Bahasa Malaysia + English (60+ strings)
- **Feedback Button** — 3 preset options (helpful / confusing / wrong price)
- Demo data fallback when real MPOB data unavailable
- GitHub Pages deployment workflow (auto-build on push)
- Riverpod state management + go_router navigation
- 15 unit tests for price models and verdict logic

### Tech Stack
- Flutter Web 3.41.6, Dart 3.11.4
- flutter_riverpod, go_router, fl_chart, google_fonts, http

## [0.1.0] - 2026-04-12

### Added
- **Backend MPOB BEPI Scraper** — Python scraper for CPO spot price + FFB regional prices
- **Commodities API Fallback** — backup data source when MPOB is unavailable
- **Firestore + JSON Writer** — dual-write to Firestore (primary) and local JSON (fallback)
- **Health Monitor** — consecutive failure tracking + Telegram alerts
- **GitHub Actions Cron** — 8:30am + 4:30pm MYT scraper schedule (Mon-Fri)
- **MACP v2.2 Protocol** — `.macp/` directory with agents, handoffs, validation, ethical framework
- **QQ Genesis Master Prompt v1.0** — CSO identity and session protocol
- 28 backend unit tests (all passing)
- Core formula: `Price/mt = Price_1% x Graded_OER%` (confirmed from PV-85935)

## [0.0.1] - 2026-04-12

### Added
- Initial repository setup
- README with Genesis Master Prompt v1.2
- LICENSE (MIT)

---

**Legend:**
- M1 = Daily Price Dashboard
- M2 = Fair Price Calculator
- M4 = Price History Chart
- M3 = My Sales Journal (planned)
- M5 = Dealer Transparency Map (planned)
