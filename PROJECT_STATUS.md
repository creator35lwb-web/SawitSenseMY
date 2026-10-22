# SawitSenseMY — Project Status

**This file is the single source of truth for the project's current state.** SS (Claude Code) maintains it and updates it at the end of every working session.

**Last updated:** 23 October 2026 (v0.3.17 verified live; the estimate measured against MPOB's official price, K25; D22 raised, D21 on hold) · SS (Claude Code)

> **Next session starts here:**
> 1. Read the newest handoff, `.macp/handoffs/20261023_SS_estimate-vs-mpob.md`.
> 2. Routine checks:
>    - open issues and PRs;
>    - `gh api repos/creator35lwb-web/SawitSenseMY/dependabot/alerts?state=open`;
>    - the OSV check on `backend/requirements.lock`: `cd backend && python -m monitor.vulnerabilities`, the same check the weekly watchdog runs (D19). Dependabot only sees the 2 direct Python packages (D17).
> 3. MPOB's October OER is due around mid-November. Check that the live `oer.month` moves from 9 to 10, that `oer.in_app_since` takes that run's date, and that "How is this calculated?" shows October.
> 4. Check that the first scheduled "Vulnerability watchdog" run (Monday 26 Oct, 10:23 MYT) passed: `gh run list --workflow vulnerability_watchdog.yml`.
> 5. **D22 awaits Alton:** show MPOB's official daily FFB reference price instead of the estimate (K25). D21 is approved but on hold until D22 is decided. D15 (web first, store later), D9 and D6 stay Alton's calls.
---

## At a glance

| | |
|---|---|
| Live site | https://creator35lwb-web.github.io/SawitSenseMY/ |
| Version | **0.3.17 live** (EN, BM and 中文; feedback form; Share button; "Latest from MPOB"; checked every 2 hours) |
| Data mode | **Indicative, and measurably off (K25).** The price per 1% OER is estimated as MPOC's daily CPO price × 0.01 × 0.93, the same for every region ([ADR-001](docs/ADR-001-mpob-data-source-change.md)). MPOB's official daily FFB reference price by region turned out to be public ([MPOB's daily summary](https://price.mpob.gov.my/pdf/daily/ffb/2026-10-21), found on 23 Oct). Against it, in October 2026 the estimate was 6–11% too low in Peninsular Malaysia and 1–6% too high in Sabah and Sarawak. D22 proposes showing MPOB's official price instead. |
| Live site freshness | **Good, with two incidents (K22, K23).** The schedule asks for a check every 2 hours (D13); GitHub runs 3–5 a day. From 17 to 22 Oct the prices were 88% GREEN, 12% AMBER and 0.8% RED. The RED was 68 min on 21 Oct, after a run timed out while MPOB was down (K23). Mornings (06:00–12:00 MYT) were 100% GREEN. 9–17 Oct: 90% GREEN, 0% RED. The freshness watchdog checks that the live site matches `main`, and that `main` has had new data within a day. |
| Data pipeline | The scraper runs every 2 hours, every day (since #21, D13) and dispatches a deploy after each data commit. Supply chain: 17 hash-locked packages, wheels only, checked weekly for known vulnerabilities (D19). |
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
- **The estimate measured against MPOB's official price** (23 Oct, K25):
  - MPOB publishes its "Daily FFB Reference Price Summary by Region (Mill Gate) (RM/1% OER)" as a PDF that needs no login ([October 2026](https://price.mpob.gov.my/pdf/daily/ffb/2026-10-21), last updated 22 Oct, 12:00 pm). MPOB's portal palmoilpedia.mpob.gov.my has also posted monthly regional reference prices (the latest seen: September 2025). ADR-001 (May 2026) believed the daily figures were behind a licensee login; only the old BEPI pages are.
  - On 21 Oct MPOB's official prices were North 47.75, South 48.12, Central 48.05, East Coast 48.00, Sabah 43.00 and Sarawak 43.42. SawitSense showed 44.33 for every region.
  - Over the 15 October trading days in `history.json`, the estimate was below MPOB in every Peninsular region on every day: 5.9–10.8% lower, 7.9–8.6% on average. It was 0.9–5.6% above in Sabah (3.0% on average), and 0.6% below to 4.0% above in Sarawak (1.7% on average).
  - At 20% OER on 21 Oct, that is RM 887/t from SawitSense against RM 962/t from MPOB in the South. A dealer paying RM 850/t gets GREEN ("fair", within 5%) from SawitSense, but is 11.7% below MPOB's mill-gate price.
  - Why the regions differ: MPOB calls these daily FFB transaction prices, published as a guide; it doesn't fix FFB prices (parliamentary reply, 12 Mar 2015). They follow each region's own market, and East Malaysia runs about RM 4–5 per 1% OER below the Peninsula. The estimate starts from one national CPO price and a fixed factor, so it can't differ by region.
  - Where 0.93 came from: one dealer receipt (PV-85935, 17 Mar 2026) and a worked example from when CPO was about RM 2,624. It was never checked against MPOB's figures, because they were thought to be private.
  - Not affected: the CPO price and MPOB's regional OER averages are exact copies of their sources.
- **v0.3.17 is live, checked after #37 and #38 merged** (23 Oct): the merge's deploy succeeded and `version.json` reads 0.3.17+19. At 360 px the "Latest from MPOB" card shows its two links and note, and no OER month or date, in EN, BM and 中文.
- **MPOC sometimes shows a bot check** (23 Oct): from SS's machine, MPOC's page came back as "please wait while your request is being verified", with no price table. The scraper's runs on GitHub still read it, but this may be what #33 saw. SS does not try to get past such checks.
- **The vulnerability watchdog works on `main`, checked after #36 merged** (23 Oct):
  - A manual run (39822585297) found no known vulnerabilities in the 17 packages, in 16 s. The alert step was skipped, as it should be on a pass.
  - GitHub lists the workflow as active, so the weekly schedule is registered. The first scheduled run is Monday 26 Oct, 10:23 MYT.
  - The first scheduled scraper run on the merged #34 and #35 code (39819660876, 17:05 UTC) succeeded in under 30 s, and its deploy put it live.
- **#34 and #35 are live, checked after they merged** (23 Oct):
  - A manual scraper run on the merged code (39817737419) installed `certifi` 2026.10.19 and finished in 24 s. MPOC and MPOB both answered, so the new retries and time limits weren't needed. Issue #33 closed with #35.
  - The OSV check of the 17 locked Python packages found 0 vulnerabilities, and there are no Dependabot alerts.
  - Feedback: with Alton's go-ahead, SS read the sheet. It still holds 1 response, the one from 16 Oct that became D18.
  - D19 approved and built in #36.
- **Health check, 22 Oct 2026:**
  - **Runs since 17 Oct:**
    - scraper: 2 incidents (below), otherwise all succeeded (108 of 110 since 21 Sep);
    - deploys: 24 succeeded;
    - freshness watchdog: 21 passed;
    - feedback form watchdog: passed daily.
  - **Incident, 21 Oct 07:31 UTC (K23):** MPOB's servers stopped answering. Each request waited about a minute, and the OER lookup tried 3 months × 3 attempts. The job hit its 10-minute limit and was cancelled, so MPOC's fresh price wasn't published either. The alert only fired on *failure*, so nobody was told. Prices went RED for 68 min until the next run. Fixed in #35.
  - **Incident, 22 Oct 11:43 UTC (K22, issue #33):** MPOC answered with a page that had no price table. The last good prices stayed live (K7), and the alert fired. The page read normally again by 14:38 UTC, with the same layout. #35 makes the scraper fetch such a page again before giving up, and log what the page was.
  - **Security:** the OSV check found **GHSA-6q48-6c7w-9gw2 in `certifi` 2026.7.22** (published 20 Oct, rated critical): a trusted root CA whose intermediates' keys were compromised. Dependabot couldn't see it (D17). Fixed in #34 (`certifi` 2026.10.19); 0 vulnerabilities after the bump.
  - **GitHub Actions was degraded on 22 Oct** (incident from 14:18 UTC), which delayed the scheduled runs and SS's manual run.
- **v0.3.16 is live, checked after #31 merged** (17 Oct):
  - The merge's deploy succeeded, and `version.json` reads 0.3.16+18.
  - A manual scraper run (38979439698, the same job as the 2-hourly one) wrote `oer.in_app_since: "2026-10-12"`, with no warnings. The deploy it dispatched put that live.
  - In a real browser at 360 px, the card reads "These prices use MPOB's OER for Sep 2026, added on 12 Oct." in English, and the same in 中文.
  - Tapping its links opens https://mpob.gov.my/current-news/ and https://mpob.gov.my/press-release/.
- **The feedback form watchdog passes on GitHub** (17 Oct, after #30 merged; run 38976448380): the form is open and matches the app.
- **Feedback works end to end (17 Oct 2026):** the first real response is in Alton's sheet (16 Oct: 4 of 5, "This is helpful", with the app details `v0.3.15 · en · prices …` filled in). From #30, a daily watchdog checks that the form stays open and matches the app.
- **Health check, 17 Oct 2026:**
  - Since 9 Oct: 30 scheduled scrapes, 31 deploys and 25 watchdog runs, all succeeded.
  - No open issues, PRs, Dependabot alerts or Discussions. The OSV check of the 17 locked Python packages found 0 vulnerabilities.
  - MPOB's **September OER arrived on 12 Oct** and is live (`oer.month` 9): Malaysia 20.26%, Sabah 21.25%, Sarawak 19.96%. Each region's fair price is the price per 1% OER (RM 42.96 on 17 Oct) × its OER, and Sabah and Sarawak use their own state figures (K4 still holds).
- **v0.3.15 is live, checked after #28 merged** (9 Oct): the deploy succeeded, `version.json` reads 0.3.15+17, and at 360 px every region name shows in full. The profile badge (creator35lwb-web#4) reads "live: v0.3.15".
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
| Usage | **Unknown.** The site has no analytics, by design. The GitHub repository had 33 page views from 5 visitors in the 14 days to 17 Oct (3 in the 14 days to 1 Oct). Feedback arrives through the Google Form (D14), which Alton reads: 1 response by 17 Oct |

---

## Open pull requests

| PR | What it does |
|----|--------------|
| [#39](https://github.com/creator35lwb-web/SawitSenseMY/pull/39) | Records only: v0.3.17 verified; the estimate measured against MPOB's official price (K25); D22 raised |

---

## Open issues

| ID | Severity | Issue | Next step |
|---|----------|-------|-----------|
| K25 | 🔴 | The main number, the price per 1% OER, is an estimate (CPO × 0.01 × 0.93) that MPOB's official daily price shows to be 6–11% too low in Peninsular Malaysia and 1–6% too high in Sabah and Sarawak (October 2026). It makes the Fair Price verdict too lenient in the Peninsula: an offer about 12% below MPOB's mill-gate price can show GREEN | D22: show MPOB's official price. Until then, the banner's "use as guidance" stands |
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
| K24 | The "Latest from MPOB" card said "These prices use MPOB's OER for Sep 2026, added on 12 Oct." Beside a price updated minutes before, the dates read as out of date; in 中文 it said 于10月12日更新, "updated on 12 Oct". And it wasn't true: the price per 1% OER comes from MPOC's CPO price alone, the same in every region. Spotted by Alton (D20) | #38 |
| K23 | When MPOB's servers stopped answering (21 Oct), a run tried 3 months × 3 attempts at about a minute each, hit the job's 10-minute limit and published nothing, not even MPOC's fresh price. The cancelled run raised no alert | #35 |
| K22 | MPOC once answered with a page that had no price table (22 Oct, issue #33). The scraper gave up at once, without saying what the page was | #35 |
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
| D19 | **A weekly automatic vulnerability check of the Python lock file.** Dependabot reads only the 2 packages named in `requirements.txt`, not the 17 in the hash-locked `requirements.lock` (D17). So SS runs an OSV check each session, which caught the `certifi` advisory (#34) two days after it was published. A small weekly workflow, standard library only, would query OSV for all 17 packages and open a `security-alert` issue on a hit, so a gap between sessions can't hide one | **Done in #36 (verified on `main`, 23 Oct).** Alton approved on 23 Oct. `.github/workflows/vulnerability_watchdog.yml` runs `backend/monitor/vulnerabilities.py` every Monday at 10:23 MYT, and on pull requests that change the lock file. It installs nothing and sends OSV only package names and versions. A hit, or a run that can't finish, opens a `security-alert` issue listing each advisory, its severity and the fixed version |
| D18 | **MPOB updates in the app.** The first feedback (16 Oct) asked for "the latest MPOB news" to keep Sawit information up to date. SS recommends the small version: a "What's new from MPOB" line on the dashboard that says when MPOB's data in the app last changed (e.g. "September OER, released 12 Oct, is now in the prices"), plus a link to MPOB's own announcements page. SawitSense would not copy or summarise news articles: that needs checking for accuracy, raises copyright questions, and adds a source that can break | **Done in #31 (verified live, 17 Oct).** Approved by Alton on 17 Oct. The card links to MPOB's daily palm oil news round-up and its press releases Its OER line was removed in v0.3.17 (D20, #38). |
| D20 | **The OER line on "Latest from MPOB".** Alton (23 Oct): "OER for Sep 2026 … added on 12 Oct" may read as outdated or misleading; should the card mention no date? SS checked, and the line was also untrue (K24): the dashboard's prices per 1% OER don't use MPOB's OER. Dropping only the dates would leave an untrue line, so SS recommends removing the sentence. The card keeps MPOB's news links, and the OER month stays in "How is this calculated?", where it is used and can be checked against MPOB's page | **Done in #38 (verified live, 23 Oct).** Alton approved it by merging. The scraper still records `oer.in_app_since` in the open data |
| D21 | **Say exactly what the prices are made from.** The banner says regional prices "are derived from MPOC daily CPO settlement and MPOB monthly OER", and every region card says "Source: Derived (MPOC CPO × MPOB OER)", in English even in BM and 中文. But the price per 1% OER is the same in every region and comes from MPOC's CPO price alone (CPO × 0.01 × 0.93). MPOB's OER only gives the regional averages in "How is this calculated?". Six identical prices, each labelled with MPOB's regional OER, invite the question why they don't differ. SS recommends that the banner say the prices come from MPOC's daily CPO price, and that each card's source line say "MPOC CPO price" in the reader's language. The new BM and 中文 wording needs a native reader's check | **Approved by Alton (23 Oct), on hold for D22.** If D22 goes ahead, the prices become MPOB's own and the banner and labels change with them. If not, SS builds D21 as approved |
| D22 | **Show MPOB's official daily FFB reference price instead of the estimate (K25).** MPOB publishes its daily price per 1% OER for each region, at the mill gate, as a public PDF. The scraper would read it after MPOB's daily update and check every figure. The dashboard and the calculator would then show MPOB's regional prices, each with its date and a link to MPOB's PDF, so readers can check them. The 0.93 estimate would be retired; on a day MPOB hasn't published, the last official prices stay with their date (K7). The Fair Price verdict would need a note that dealers' prices sit below the mill-gate price by their transport and margin. MPOB's disclaimer has no reuse terms. The page shows © MPOB, and the PDF lists MPOB staff to contact, so Alton may wish to tell MPOB, or ask first. The new wording in BM and 中文 needs a native reader's check | **Open. Alton's call.** SS recommends yes |

---

## Backlog

1. Security: handle any Dependabot alert or `security-alert` issue in a normal PR. The vulnerability watchdog checks `requirements.lock` weekly (D19), and SS runs the same check each session (D17).
2. Feedback (D14): live, and watched daily (#30). Alton reads the form's responses; SS picks up anything that needs a fix. The first one became D18. SS reads the sheet only when Alton says yes; on 23 Oct it still held that one response.
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
| Active agent's Genesis | [SS_Claude_Code_Genesis_Master_Prompt_v1.1.md](SS_Claude_Code_Genesis_Master_Prompt_v1.1.md) |
| Earlier Genesis docs | [QQ (Qoder)](QQ_Genesis_Master_Prompt_v1.0.md), [QQ (Perplexity)](QQ_Perplexity_Genesis_Master_Prompt_v1.0.md) |
| Handoffs | [.macp/handoffs/](.macp/handoffs/), one file each; April–May 2026 are in [.macp/handoffs.json](.macp/handoffs.json) |
| Reasoning logs | [.macp/reasoning/](.macp/reasoning/) |
| Ethical framework | [.macp/ethical_framework.md](.macp/ethical_framework.md) (v1.1) |
| Architecture decisions | [docs/](docs/) |
| Release history | [CHANGELOG.md](CHANGELOG.md) |
