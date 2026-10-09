# SawitSenseMY — Project Status

**This file is the single source of truth for the project's current state.** SS (Claude Code) maintains it and updates it at the end of every working session.

**Last updated:** 9 October 2026 (v0.3.14 verified live; #28 region names) · SS (Claude Code)

> **Next session starts here:**
> 1. Read the newest handoff, `.macp/handoffs/20261009_SS_v0.3.15-region-names.md`.
> 2. Routine checks:
>    - open issues and PRs;
>    - `gh api repos/creator35lwb-web/SawitSenseMY/dependabot/alerts?state=open`;
>    - the OSV check on `backend/requirements.lock` (Dependabot only sees the 2 direct Python packages, D17).
> 3. MPOB's September OER is due around mid-October: check that the live `oer.month` moves from 8 to 9.
> 4. D15 (web first, store later), D9 and D6 stay Alton's calls.
---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | **0.3.14 live** (EN, BM and 中文; feedback form; Share button; checked every 2 hours). 0.3.15 in review (#28) |
| Data mode | **Indicative.** Since May 2026 MPOB's Daily FFB Reference Price has been behind a licensee login ([ADR-001](docs/ADR-001-mpob-data-source-change.md)). Regional prices are derived from the MPOC daily CPO price and MPOB's monthly OER. |
| Live site freshness | **Good (K18 closed, 9 Oct).** The schedule asks for a check every 2 hours (D13). GitHub runs 3–5 a day. Over 2–9 Oct, weekends included, the data was 87% GREEN, 13% AMBER and 0% RED, and mornings were 100% GREEN. The longest gap was 10.4 h. The freshness watchdog checks that the live site matches `main`, and that `main` has had new data within a day. |
| Data pipeline | The scraper runs every 2 hours, every day (since #21, D13) and dispatches a deploy after each data commit. Supply chain: 17 hash-locked packages, wheels only. |
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
- **v0.3.9 is live, checked after #19 merged.**
  - Deploy `#36823054923` **succeeded under the narrower permissions**, which proves K14 in a real deploy.
  - SonarCloud on `main` now shows **0 bugs and 0 vulnerabilities, rated A** for reliability and security (it was C). The quality gate passes.
  - The page's `lang` was `en` before the app started but `en-US` afterwards, on every phone. Choosing from the menu set it correctly. The startup gap is fixed in #20 (K19).
- **v0.3.14 is live, checked after #27 merged** (9 Oct):
  - The deploy succeeded, `version.json` reads 0.3.14+16, and the page serves the new link-preview tags.
  - At 360 px in a real browser, Share sits beside Feedback in EN and 中文 and opens its panel: Copy link, WhatsApp, Facebook, X, LinkedIn, Email.
  - The same screenshots showed English region names cut off ("East …", "Sara…"); fixed in #28 (K21).
- **Health check, 9 Oct 2026** (repo folder renamed locally to `SawitSenseMY`; same GitHub repo):
  - Since 2 Oct: 27 scheduled scrapes, all succeeded, each followed by a successful deploy. The watchdog ran 20 times, all passing.
  - No open issues, PRs, Dependabot alerts or Discussions. The OSV check of all 84 locked packages found 0 vulnerabilities.
  - The live site is v0.3.13 and answers HTTP 200. Data was 1.6 h old, with the CPO price of 7 Oct (RM 4,524.00) and the OER for Aug 2026. No warnings.
- **v0.3.13 is live, checked after #23 merged** (2 Oct, 00:12 UTC).
  - The merge's deploy succeeded on the new actions and Ubuntu 24.04, with no warnings.
  - A scraper run on `main` committed and pushed data under checkout v7 (`a32b821..732ea56`), and the deploy it dispatched succeeded.
  - The live bundle is v0.3.13, with data scraped at 08:15 MYT and no warnings.
- **First day of the 2-hourly schedule** (#21 merged 1 Oct, 09:49 UTC): GitHub ran scheduled scrapes at 17:00 and 22:37 UTC (01:00 and 06:37 MYT), each followed by a successful deploy. That's 2 of about 7 slots (K18).
- **Dependencies have no known vulnerabilities** (2 Oct). All 84 locked packages (67 Dart in `pubspec.lock`, 17 Python in `requirements.lock`) were checked against the OSV database: 0 found. Dependabot alerts were off then; they are now on (D17).
- **v0.3.12 is live, checked after #22 merged.** The deploy succeeded and the live bundle is v0.3.12. On the live site, Feedback → "Price looks wrong" opens the form on docs.google.com with that option selected and the app details `v0.3.12 · en · prices 2026-10-01T13:45:57+08:00`.
- **v0.3.11 is live** (#21 merged 1 Oct, 09:49 UTC). Its deploy succeeded. The first 2-hourly slots had not fired by 10:26 UTC; the cadence check is pending.
- **v0.3.10 is live, checked after #20 merged.** The deploy succeeded and the live bundle is v0.3.10. On the live site the page's `lang` is `en`, `ms` and `zh-Hans` for phones set to English, Malay and Chinese once the app starts, and it switches with the menu (K19 fixed).
- **The first run on the `:13` schedule** (1 Oct, 00:13 UTC) started at 05:45 UTC, 5 h 32 min late. The schedule move didn't help (K18, D13).
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
| [#28](https://github.com/creator35lwb-web/SawitSenseMY/pull/28) | v0.3.15: region names never cut short on small phones (K21) |

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
| K13 | The calculator's green verdict said "within 5% of MPOB benchmark" (BM and 中文 too). In indicative mode the benchmark is SawitSense's estimate, and the banner on the same screen says so | #17 |
| K14 | The deploy workflow gave Pages write access to every job (SonarCloud: 2 vulnerabilities) | #19 |
| K15 | The page had no `lang`, so screen readers couldn't tell its language (SonarCloud: bug) | #19 |
| K16 | The health monitor logged text read from `health.json`, so a crafted file could forge log lines (SonarCloud: 2 vulnerabilities) | #19 |
| K19 | After #19 the page's `lang` was still reset to `en-US` once the app started, for every language. Flutter writes the app's locale to the page, and the app declared none | #20 |
| K17 | The feedback button said "Thank you for your feedback!" but sent nothing (Firestore was retired in D5) | #22 |
| K18 | GitHub ran the twice-weekday scrapes hours late, so mornings were 60% RED. With 2-hourly slots, measured over 2–9 Oct: 87% GREEN and 0% RED overall, and 100% GREEN in the mornings | #21 (D13) |
| K21 | At 360 px the region cards cut English names short ("East …", "Sara…"): the name shared its line with the *Indicative* chip | #28 |
| K20 | Every workflow run warned that its actions target the deprecated Node 20. `ubuntu-latest` moves to Ubuntu 26 from 19 Oct 2026, which could change the scraper's Python or tooling without notice | #23 |

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
| D13 | **Check the sources every 2 hours, every day,** instead of twice on weekdays. GitHub's delays then matter far less, and weekends stop showing "Out of date" just because MPOC doesn't publish (the CPO card still shows the trading date). Cost: about 12 bot commits and deploys a day instead of 2; still free for a public repo | **Approved** (Alton, 1 Oct). In #21 |
| D14 | **The feedback button sends nothing (K17).** Make it real: its options open a short, anonymous form that Alton owns (no login needed), and in the Android app "This is helpful" opens the Play Store rating | **Done in #22 (verified live).** Alton created the form on 1 Oct from [`docs/feedback-form.md`](docs/feedback-form.md). SS checked it matches the draft word for word, needs no sign-in and has no email field, and that the app's links select the right option in a real browser |
| D15 | **A free Android app on Google Play,** built from the same Flutter code. It gives public ratings and reviews, plus installs, active devices and crash reports from Play Console, without adding any tracking to the app. **Alton:** a Play Console account (US$25 once, ID check, 2-step verification). A personal account must run a closed test with at least 12 testers for 14 days in a row before going public; an organization account with a D-U-N-S number is exempt. **SS:** the Android build via CI, keeping the last prices on the phone (D9 becomes simple in an installed app), a privacy page, the store listing in BM, EN and 中文, and signed builds with the upload key kept only in Actions secrets. The listing must say the app is not affiliated with MPOB or MPOC | **Open.** Alton asked for web vs store pros and cons (1 Oct). SS recommends **web first**: the live web app is good enough for now. Start the feedback loop with the form (D14) and Discussions (D16), then revisit the store when feedback shows demand, recruiting the 12 testers through it |
| D17 | **Turn on Dependabot alerts.** GitHub then warns when a locked package gets a known vulnerability. Alerts only, with no automatic PRs: SS handles any alert through a normal PR, because the hash-locked files need a careful update. Free for public repos | **Done** (Alton approved, 2 Oct). Alerts are on and automatic fix PRs are off; 0 open alerts. GitHub watches all 67 Dart packages and the 8 workflow actions, but only the 2 Python packages named in `requirements.txt`: it can't read the hash-locked `requirements.lock`. SS covers all 17 Python packages with an OSV check each session; 0 found on 2 Oct |
| D16 | **GitHub Discussions** for ideas and questions from the public, partners and developers. It needs a GitHub account, so it complements rather than replaces a channel for smallholders | **Done** (Alton approved, 1 Oct). Discussions are on with GitHub's default categories (Announcements, General, Ideas, Polls, Q&A, Show and tell), linked from the README |

---

## Backlog

1. Security: handle any Dependabot alert in a normal PR, and run the OSV check on `requirements.lock` each session (D17).
2. Feedback (D14): live. Alton reads the form's responses; SS picks up anything that needs a fix.
3. A Google Play app (D15): web first, revisit when feedback shows demand. It includes keeping the last prices on the phone (D9).
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
