# SawitSenseMY — Project Status

**This file is the single source of truth for the project's current state.** SS (Claude Code) maintains it and updates it at the end of every working session.

**Last updated:** 1 October 2026 (performance review and SonarCloud fixes) · SS (Claude Code)

> **Next session starts here:**
> 1. Read the newest handoff, `.macp/handoffs/20261001_SS_v0.3.9-performance-and-sonar.md`.
> 2. After Alton merges [#19](https://github.com/creator35lwb-web/SawitSenseMY/pull/19), check that:
>    - the deploy still succeeds with the narrower permissions (K14);
>    - the live page's `lang` follows the reader's language (K15);
>    - the footer reads v0.3.9.
> 3. Check when the first scheduled scrape on the `:13` cron ran.
>    - The 1 Oct, 00:13 UTC run still had not started by 05:32 UTC.
>    - SS ran the scraper by hand at 03:00 UTC (11:01 MYT), which brought in MPOC's 30 Sep price (RM 4,610.00).
>    - Use `gh run list --workflow scraper_cron.yml` **without** `--event schedule`.
> 4. Ask Alton for D13–D16:
>    - D13: freshness;
>    - D14: a real feedback channel;
>    - D15: a Google Play app;
>    - D16: GitHub Discussions.

---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | **0.3.8 live** (EN, BM and 中文; opens in the reader's language); 0.3.9 in [#19](https://github.com/creator35lwb-web/SawitSenseMY/pull/19) (SonarCloud fixes) |
| Data mode | **Indicative.** Since May 2026 MPOB's Daily FFB Reference Price has been behind a licensee login ([ADR-001](docs/ADR-001-mpob-data-source-change.md)). Regional prices are derived from the MPOC daily CPO price and MPOB's monthly OER. |
| Live site freshness | **Refreshed twice every weekday, but late.** GitHub starts the scheduled scrapes a median 4.7 h late, so on weekday mornings in Malaysia the badge shows AMBER, then RED from about 10:00 until the early-afternoon run (K18, D13). The freshness watchdog checks that the live site matches `main`. |
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
- **v0.3.5 is live, checked after #14 merged.**
  - Deploy `#36716196010` succeeded.
  - The new icons and share image return HTTP 200, the manifest lists the three intended icons, and the old 2.7 MB `logo.png` returns 404 as intended.
  - The footer reads v0.3.5.
  - Phone-emulated screenshots of the live site at 412 and 360 px show the launch screen, the logo badge, and chart labels that no longer collide.

- **v0.3.6 is live, checked after #15 merged.**
  - Deploy `#36721381958` succeeded, and the live bundle is v0.3.6.
  - On the live site at 412 and 360 px, SS ran the whole Chinese flow: dashboard, method sheet, a calculator verdict (北马 → RM 43.38; RM 700 paid → 黄灯), and History.
  - #15 was merged as drafted; no wording changes were suggested on the PR.
- **v0.3.7 is live, checked after #16 merged.**
  - Deploy `#36724782679` succeeded, and the live bundle is v0.3.7.
  - Phones emulated on the live site, each with empty storage:
    - Chinese opens in 中文, and after the reader picks English and reloads it stays English (`en` stored);
    - Malay opens in BM;
    - English and French open in English.
  - All nine top-bar titles show in full at 360 px in EN, BM and 中文.
- **v0.3.8 is live, checked after #17 merged.**
  - Deploy after the merge succeeded, and the live bundle is v0.3.8.
  - It contains "within 5% of benchmark", and the old "within 5% of MPOB benchmark" is gone.
  - On the live calculator, North (RM 43.38 × 18% = RM 780.84) with RM 780 paid gives the green verdict in all three languages, and none of them names MPOB:
    - FAIR — within 5% of benchmark;
    - ADIL — dalam 5% penanda aras;
    - 公平 — 与基准相差 5% 以内.
- **Scheduled scrapes ran every weekday through September**, 4–6 hours late under the old `:30` schedule. For example, 29 Sep at 06:01 and 14:54 UTC, and 30 Sep at 05:50 UTC. The `:13` schedule's first run is due 1 Oct, 00:13 UTC.
---

## Performance (v0.3.8, measured 1 Oct 2026)

Speed was measured on an emulated phone (412 px wide, CPU slowed 4×) loading the live site.

| Measure | Result |
|---|---|
| First visit at 1.6 Mbps / 150 ms (Lighthouse's mobile test) | Launch screen at **0.4 s**; app and prices on screen at **15.2 s** |
| First visit at 9 Mbps / 60 ms (good 4G) | Launch screen at 0.3 s; app and prices at **4.8 s** |
| First-visit download | **2.77 MB**: graphics engine (CanvasKit) 1.58 MB, app code 0.85 MB, fonts 0.27 MB, everything else 0.07 MB. Chinese adds about 0.4 MB of font pieces, once |
| Return visit | About **1 s**, with nothing re-downloaded. GitHub Pages lets browsers reuse files for 10 minutes, then re-checks them |
| Offline | Not available: Flutter's service worker only unregisters itself (D9) |
| Scheduled scrapes | 56 runs since 21 Aug started a median **4.7 h** late (0.6–11.8 h), landing around 13:30 and 22:00 MYT (K18) |
| Code quality (SonarCloud, `main`) | Quality gate passed. The 1 bug and 4 vulnerabilities found in older code are fixed in #19 (K14–K16) |
| Tests | Backend 93 and frontend 70, all passing (with #19) |
| Usage | **Unknown.** The site has no analytics, by design. The GitHub repository had 3 page views in 14 days, and the feedback button sends nothing (K17) |

---

## Open pull requests

| PR | What it does |
|----|--------------|
| [#19](https://github.com/creator35lwb-web/SawitSenseMY/pull/19) | v0.3.9: SonarCloud fixes (K14 deploy permissions, K15 page language, K16 log injection), the performance baseline, and D13/D14 raised |

---

## Open issues

| ID | Severity | Issue | Next step |
|---|----------|-------|-----------|
| K10 | 🟡 | If MPOB's BEPI ever serves data again, `run_scraper` logs it but still publishes indicative values; the authoritative path isn't wired up | Part of Track B (D6). Only needed if Alton goes ahead |
| K17 | 🟠 | The feedback button thanks the reader ("Thank you for your feedback!") but sends nothing. Firestore was retired (D5), and the code only prints to the browser console | D14, Alton's call |
| K18 | 🟠 | Weekday mornings show AMBER, then RED, because GitHub starts the twice-daily scrapes about 5 h late (the `:13` change hasn't helped so far) | D13, Alton's call |

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
| K13 | The calculator's green verdict said "within 5% of MPOB benchmark" (BM and 中文 too). In indicative mode the benchmark is SawitSense's estimate, and the banner on the same screen says so | #17 |
| K14 | The deploy workflow gave Pages write access to every job (SonarCloud: 2 vulnerabilities) | #19 |
| K15 | The page had no `lang`, so screen readers couldn't tell its language (SonarCloud: bug) | #19 |
| K16 | The health monitor logged text read from `health.json`, so a crafted file could forge log lines (SonarCloud: 2 vulnerabilities) | #19 |

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
| D9 | **Offline-first scope.** Caching prices on the phone only helps once the app itself has loaded. True offline use needs a service worker that caches the app, plus a new storage package. Adding a package needs Flutter to regenerate `pubspec.lock`: either installed on Alton's machine, or through a CI job that SonarCloud would flag for review. Chinese text also needs its font pieces cached, because Flutter loads them from Google Fonts the first time (about 400 KB) | **Next session** (Alton, 30 Sep). SS recommends deferring until smallholders report connection problems; #11 and #12 already cover most of the need |
| D10 | **Chinese (CN)**, which ethical framework v1.1 requires | Done in #15 (verified live). Better wording from native readers is a one-line change in `app_zh.dart` |
| D11 | **Remember the reader's language:** open in the phone's language on the first visit, and remember the reader's last choice on that phone (browser storage, no personal data, no new package) | Done in #16 (verified live) |
| D12 | **Repository housekeeping:** GitHub deletes each PR's branch after merge ("Automatically delete head branches"), and the 16 old merged branches are removed | Done on 1 Oct (Alton: "GO!"). Only `main` remains. Every deleted branch was already inside `main` and can be restored from its PR page |
| D13 | **Check the sources every 2 hours, every day,** instead of twice on weekdays. GitHub's delays then matter far less, and weekends stop showing "Out of date" just because MPOC doesn't publish (the CPO card still shows the trading date). Cost: about 12 bot commits and deploys a day instead of 2; still free for a public repo | **Open. Alton's call.** SS recommends it |
| D14 | **The feedback button sends nothing (K17).** Make it real: its options open a short, anonymous form that Alton owns (no login needed), and in the Android app "This is helpful" opens the Play Store rating | **Open. Alton's call.** SS recommends this. Until the form exists, the false "Thank you" should go |
| D15 | **A free Android app on Google Play,** built from the same Flutter code. It gives public ratings and reviews, plus installs, active devices and crash reports from Play Console, without adding any tracking to the app. **Alton:** a Play Console account (US$25 once, ID check, 2-step verification). A personal account must run a closed test with at least 12 testers for 14 days in a row before going public; an organization account with a D-U-N-S number is exempt. **SS:** the Android build via CI, keeping the last prices on the phone (D9 becomes simple in an installed app), a privacy page, the store listing in BM, EN and 中文, and signed builds with the upload key kept only in Actions secrets. The listing must say the app is not affiliated with MPOB or MPOC | **Open. Alton's call.** SS recommends yes, after D13 and D14. The closed test doubles as the first structured feedback from smallholders |
| D16 | **GitHub Discussions** for ideas and questions from the public, partners and developers. It needs a GitHub account, so it complements rather than replaces a channel for smallholders | **Open. Alton's call.** SS recommends turning it on now (free) |

---

## Backlog

1. Check the sources every 2 hours (D13), if Alton agrees.
2. A real feedback loop (D14, D16), if Alton agrees.
3. A Google Play app (D15), if Alton agrees. It includes keeping the last prices on the phone (D9).
4. Optional: fold in better Chinese or Malay wording whenever a native reader suggests it. Each change is one line in `frontend/lib/l10n/`.

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
