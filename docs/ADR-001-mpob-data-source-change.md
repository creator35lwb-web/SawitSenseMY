# ADR-001: MPOB BEPI Portal Restructure & SawitSense Recovery (Path C)

- **Status:** Accepted (v0.3-recovery)
- **Date:** 2026-05-21
- **Authors:** QQ (Perplexity), under Alton's authority (part of the YSenseAI ecosystem)
- **Original SawitSense data layer:** QQ (Qoder CSO)
- **Amended:** 2026-09-30 by SS (Claude Code); see [Amendments](#amendments)

## Context

Between v0.2.1 and May 2026, MPOB restructured the BEPI portal at
`bepi.mpob.gov.my`. The two anonymous endpoints SawitSense depended on now
respond with HTTP 404 and the underlying data (Daily FFB Reference Price at
1% OER, broken down by 6 regions) is gated behind a licensee login on the
new Prestasi Sawit portal:

> "PRIVILEGED ACCESS ONLY TO MPOB LICENSEES"
>
> Compilation of reports and latest figures of various sectors of Malaysian
> oil palm industry such as area, production, stocks, **prices**, exports and
> seeds.

The Commodities-API fallback was effectively dead too — the
`COMMODITIES_API_KEY` GitHub Actions secret was empty, so every scheduled
run since at least 2026-05-14 failed silently (no Issues, no alerts).

## Decision

Adopt a **two-track recovery**:

### Track A — Ship today (this ADR)
Restore the data pipeline using **only public, anonymous sources**, and label
the output as **INDICATIVE** so smallholders are told honestly that the
values are guidance, not a legal benchmark.

| Concern | Source | Cadence | Reliability |
|---|---|---|---|
| Daily CPO settlement price (RM/tonne) | MPOC — [Daily Palm Oil Prices](https://mpoc.org.my/daily-palm-oil-prices/) | Trading days | High (static HTML, no JS, no auth) |
| Monthly state-level OER % | MPOB — `prestasisawit.mpob.gov.my/api/oer` | Monthly, in arrears | High (official MPOB API) |
| Per-region indicative Price_1%OER | Derived: `CPO × 0.01 × share_factor` | Recomputed per run | Indicative (see below) |

The share factor `0.93` is anchored on:
- Payment voucher PV-85935 (the historical Sdn Bhd receipt referenced in the
  README and `test_calculate_fair_price`).
- The README's South-region calibration example (CPO ~RM 2,624 → Price_1%
  ~RM 24.40 → factor ≈ 0.93).

This coefficient is **transparently documented** in `run_scraper.py` and is
**NOT** the rejected `CPO × 0.2? × 0.7?` dealer shorthand. It is an explicit,
auditable approximation used only to keep the Fair Price calculator
functional while Track B is resolved.

### Track B — Restore authoritative source (separate decision)
Pursue an MPOB licensee registration so the scraper can authenticate to
`prestasisawit.mpob.gov.my/en/sectoral` and pull the **official** Daily FFB
Reference Price. This requires:

1. Alton's sign-off on creating a licensee account.
2. Legal review of MPOB's terms-of-service for programmatic access.
3. Storage of credentials in GitHub Actions secrets (`MPOB_USERNAME`,
   `MPOB_PASSWORD`).
4. Failure-mode planning (account lockout, rate-limit, ToS change).

Tracked separately; this ADR explicitly does NOT authorize Track B.

## Consequences

### Positive
- **Pipeline runs again** — smallholders see fresh data after 16+ failed runs.
- **No regressions** to the core formula module (`mpob_bepi.py` math
  helpers unchanged; all v0.2 tests still pass).
- **Silent decay can't recur** — the workflow now auto-files a GitHub Issue
  on any failed run, with deduplication so it doesn't spam. (It recurred one
  step later, at the deploy; see Amendments.)
- **Honest labelling** — every payload, region, and (eventually) UI banner
  carries `is_indicative: true` and the `indicative_notice` text.

### Negative / Accepted risk
- Frontend currently does not yet render the "indicative" banner; a
  follow-up frontend PR will surface it. Until then, the JSON exposes the
  flag for any API consumer. (Resolved by PR #3, 21 May 2026.)
- The 0.93 share factor will drift if mill margin / transport assumptions
  change. Track B restoration is the durable fix.

## Implementation notes (this PR)

- New: `backend/scrapers/mpoc_cpo.py` — daily CPO from MPOC.
- New: `backend/scrapers/mpob_oer.py` — monthly OER from Prestasi Sawit API.
- Patched: `backend/scrapers/mpob_bepi.py` — graceful 404 handling; math
  helpers untouched.
- Rewritten: `backend/run_scraper.py` — new orchestration; back-compatible
  payload shape (`cpo`, `ffb`, plus new `oer` object).
- Patched: `.github/workflows/scraper_cron.yml` — Issue-on-failure step,
  concurrency lock, `permissions:` block.
- New: `backend/tests/test_mpoc_cpo.py`, `test_mpob_oer.py`,
  `test_run_scraper.py`.
- Legacy `commodities_fallback.py` is **retained** as a last-resort CPO
  fallback; it self-disables when `COMMODITIES_API_KEY` is unset.

## References

- Failing workflow runs: `gh run list --repo creator35lwb-web/SawitSenseMY --workflow=scraper_cron.yml`
- Source upstream pages:
  - https://bepi.mpob.gov.my/ (homepage, "Bepi Maintenance")
  - https://prestasisawit.mpob.gov.my/en/sectoral (licensee gate)
  - https://prestasisawit.mpob.gov.my/en/oer
  - https://mpoc.org.my/daily-palm-oil-prices/

## Amendments

### 2026-09-30 — Post-incident notes (SS (Claude Code))

- **Live site frozen, 21 May – 30 Sep 2026.** The scraper commits data with
  `GITHUB_TOKEN`, and GitHub never starts other workflows from those pushes,
  so `deploy_web.yml` never ran after the 21 May merges. Every scrape
  succeeded, but none of the Path C data reached the live site, and the
  History tab fell back to synthetic demo prices. Fixed in #6: the scraper
  dispatches the deploy, and a watchdog now compares the live site with
  `main`.
- **Sarawak OER.** `mpob_oer.py` assumed JPN/ISO state codes; MPOB uses
  Sabah = 13 and Sarawak = 14. From 21 May until #7, `latest.json` and
  `prices_*.json` published Sabah's OER as Sarawak's (Aug 2026: 21.06%
  instead of 19.58%, overstating Sarawak's indicative fair price by about
  RM 64/t). The app did not display these fields. Fixed in #7, which also
  cross-checks every run against MPOB's published totals. Historical files
  are unchanged (PROJECT_STATUS.md, decision D4).
- **Alerting in practice.** No repository secrets have been configured, so
  the Telegram alert and the Commodities-API fallback have never been
  active and Firestore has never been written. GitHub issues are the
  working alert channel.
- **Track B** remains undecided (PROJECT_STATUS.md, decision D6). Sign-off
  rests with Alton; the earlier text naming CIO/XV was an attribution error
  (handoff-003).

### 2026-09-30: Failure behaviour (SS (Claude Code), #11)

- **A failed source never replaces the last good data.**
  - With no CPO price (MPOC and the fallback both failed), nothing is
    published. The last good snapshot stays live, the freshness badge shows
    its age, and the run fails so the alert issue fires.
  - If MPOB's OER fetch fails, the previous `oer` block is carried forward.
    It is marked `carried_forward: true` and raises a data-quality warning.
  - This replaces the earlier behaviour of writing a `success: false`
    marker, or a payload without prices, over `latest.json`.
- **Track B wiring.** If MPOB's BEPI ever serves data again, `run_scraper`
  logs it but still publishes indicative values. Publishing the
  authoritative price is part of Track B.
- **Verifiable sources (#10).** The payload publishes
  `ffb.indicative_share_factor` and `oer.source_page_url`, so anyone can
  redo the sum and check the OER on MPOB's public page.
