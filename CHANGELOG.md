# Changelog

All notable changes to SawitSense MY will be documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.12] - 2026-10-01

### Fixed
- The Feedback button now opens a short Google Form (owned by Alton), with the reader's choice selected and the app details filled in: version, language, and when the prices on screen were updated. No personal data is sent, and no sign-in is needed. It used to say "Thank you for your feedback!" while sending nothing (K17, D14, #22)

## [0.3.11] - 2026-10-01

### Changed
- Prices are checked every 2 hours, every day, instead of twice on weekdays. GitHub starts scheduled runs hours late, so mornings in Malaysia often showed out-of-date data. Weekends now stay up to date with the latest trading day's price (D13, #21)
- The freshness watchdog runs every 6 hours, every day. It alerts when no new data has arrived for a day; the limit was 4 days (#21)

### Added
- GitHub Discussions are open for ideas and questions, linked from the README (D16)

## [0.3.10] - 2026-10-01

### Fixed
- The page's language was reset to `en-US` as soon as the app started, so screen readers used English rules for BM and Chinese too. The app now tells Flutter the reader's language, and Flutter sets the page's `lang` (`en`, `ms`, `zh-Hans`) at start and on every change. The extra script from 0.3.9 is removed. Flutter's own built-in labels (Copy/Paste, menu tooltips) stay in English, as before (K19, #20)

### Added
- `docs/feedback-form.md`: the draft feedback form for D14. It has 3 questions with a star rating, asks for no personal data, and needs no sign-in (#20)

## [0.3.9] - 2026-10-01

### Fixed
- The page now declares its language: `en`, then the reader's language (`ms`, `zh-Hans`) at start and on every change, so screen readers use the right voice (K15, #19)

### Security
- The deploy workflow is read-only by default. Only the deploy job can write to GitHub Pages (K14, #19)
- The health monitor parses the failure count from `health.json` as a number before using or logging it, so a crafted file can't forge log lines (K16, #19)

## [0.3.8] - 2026-09-30

### Fixed
- The calculator's green verdict said "FAIR — within 5% of MPOB benchmark", in BM and 中文 too. While prices are indicative, the benchmark behind a region's price is SawitSense's estimate, not MPOB's (ADR-001). It now says "within 5% of benchmark", like the amber and red verdicts, and a test keeps verdicts from naming MPOB (K13, #17)

## [0.3.7] - 2026-09-30

### Added
- The app opens in the reader's language (D11, #16):
  - their last choice on that phone;
  - otherwise the phone's own language, if it's English, Malay or Chinese (any Chinese gets Simplified);
  - otherwise English.

  Before, every visit started in English. The choice is kept in the browser as `en`, `ms` or `zh`: that isn't personal data, and it never leaves the phone.

### Fixed
- At 360 px the dashboard title was cut off: "Daily Price Dash…" in English, "Papan Pemuka …" in BM. Long top-bar titles now shrink to fit, with no wording changes (#16)

## [0.3.6] - 2026-09-30

The Chinese strings were drafted by SS for review by a native reader (D10).

### Added
- Simplified Chinese (简体中文), the third language the ethical framework asks for. It uses the terms Malaysian Chinese readers see in the press: 原棕油 (CPO), 鲜果串 (FFB), 出油率 (OER), and 北马 / 中马 / 南马 for the regions. Dates read 2026年9月30日, and chart labels read 9月28日. Asides that are italic in English and BM stay upright, since Chinese has no italics. Characters load from Flutter's built-in Noto Sans SC fallback, about 400 KB the first time (#15)
- Language menu in the top bar (EN / BM / 中文) in place of the EN|BM toggle. It lists each language in its own script, so anyone can find theirs whichever language is showing (#15)

### Fixed
- The feedback dialog's "Close", the calculator's "Required" and "Invalid number", and the verdict badge's GREEN / AMBER / RED showed in English in every language. BM now shows Tutup, Wajib diisi, Nombor tidak sah and HIJAU / AMBAR / MERAH (#15)

## [0.3.5] - 2026-09-30

Checked on phone-sized screens (412 and 360 px) before merging, using the new CI preview build.

### Added
- Launch screen: the emblem, name, tagline and a loading bar show at once while the app loads, instead of a blank white page (#14)
- Right-sized icons: favicon (2 KB), iOS icon, PWA icons including a separate maskable icon that survives Android's circular crop, and an absolute share image for link previews. `frontend/tool/make_icons.py` derives them all from one master logo (#14)
- CI uploads each PR's web build as a 3-day preview artifact (#14)

### Fixed
- The top-bar logo was the whole 2048 px, 2.7 MB logo squeezed into a ~40 px white square. It is now the emblem alone on a rounded white badge, at 31 KB (#14)
- History chart:
  - Y-axis labels no longer collide ("5009" over "5000"); gridlines are round numbers (4600–5000)
  - Dates are spaced and read "28 Sep", with room for the latest one
  - The line no longer overshoots between days (#14)
- The History table shows every day in the window, not only the latest ten, with BM/EN headers (#14)

## [0.3.4] - 2026-09-30

### Changed
- The History tab loads one small `history.json` (about 4 KB, rewritten every run) instead of one request per day for 30 days. That was about 22 files plus 404s for weekends. It falls back to the per-day files if the index can't be read (#12)
- Scraper schedule moved from :30 to :13 past the hour to reduce GitHub's scheduling delays; runs had been starting 4–8 hours late (#12)

### Added
- CI builds the web app on every PR, so web-only compile errors are caught before merge (#12)

## [0.3.3] - 2026-09-30

### Fixed
- A failed data source no longer replaces the last good data (#11):
  - If there is no CPO price, nothing is published, and the last good snapshot stays live with its freshness badge ageing honestly.
  - If MPOB's OER is unavailable, the previous month's figures are carried forward, marked `carried_forward`, and an alert is raised.
- When legacy MPOB BEPI returns data, the log no longer claims it switched to the authoritative path; that isn't wired up yet (Track B) (#11)

## [0.3.2] - 2026-09-30

Every figure can now be checked against a public page, or recalculated by hand.

### Added
- Tappable source on the CPO card, opening MPOC's daily prices page, which shows the same settlement price (#10)
- "How is this calculated?" on the Dashboard and Calculator. It opens a panel with (#10):
  - the indicative price as a sum anyone can redo (e.g. RM 4664.00 × 0.01 × 0.93 = RM 43.38)
  - each region's MPOB OER, linked to MPOB's public OER page
  - a plain note that MPOB's official FFB Reference Price is licensee-only
- "Open data" link in the footer to every published price snapshot (#10)
- Data payload: `ffb.indicative_share_factor` and `oer.source_page_url`, so the figures can be checked (#10)

### Changed
- "Learn more (ADR-001)" opens the document instead of copying its link (#10)

### Fixed
- The six regional cards showed the same price per 1% OER with no explanation. The panel now explains that it comes from one national CPO price, and that regions differ by OER (#10)

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
