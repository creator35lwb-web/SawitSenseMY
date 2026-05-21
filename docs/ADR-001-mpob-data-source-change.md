# ADR-001: MPOB BEPI Portal Restructure & SawitSense Recovery (Path C)

- **Status:** Accepted (v0.3-recovery)
- **Date:** 2026-05-21
- **Authors:** QQ (Perplexity), on behalf of YSenseAI / CIO XV
- **Original SawitSense data layer:** QQ (Qoder CSO)

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

The Commodities-API fallback was effectively dead too \u2014 the
`COMMODITIES_API_KEY` GitHub Actions secret was empty, so every scheduled
run since at least 2026-05-14 failed silently (no Issues, no alerts).

## Decision

Adopt a **two-track recovery**:

### Track A \u2014 Ship today (this ADR)
Restore the data pipeline using **only public, anonymous sources**, and label
the output as **INDICATIVE** so smallholders are told honestly that the
values are guidance, not a legal benchmark.

| Concern | Source | Cadence | Reliability |
|---|---|---|---|
| Daily CPO settlement price (RM/tonne) | MPOC \u2014 [Daily Palm Oil Prices](https://mpoc.org.my/daily-palm-oil-prices/) | Trading days | High (static HTML, no JS, no auth) |
| Monthly state-level OER % | MPOB \u2014 `prestasisawit.mpob.gov.my/api/oer` | Monthly, in arrears | High (official MPOB API) |
| Per-region indicative Price_1%OER | Derived: `CPO \u00d7 0.01 \u00d7 share_factor` | Recomputed per run | Indicative (see below) |

The share factor `0.93` is anchored on:
- Payment voucher PV-85935 (the historical Sdn Bhd receipt referenced in the
  README and `test_calculate_fair_price`).
- The README's South-region calibration example (CPO ~RM 2,624 \u2192 Price_1%
  ~RM 24.40 \u2192 factor \u2248 0.93).

This coefficient is **transparently documented** in `run_scraper.py` and is
**NOT** the rejected `CPO \u00d7 0.2? \u00d7 0.7?` dealer shorthand. It is an explicit,
auditable approximation used only to keep the Fair Price calculator
functional while Track B is resolved.

### Track B \u2014 Restore authoritative source (separate decision)
Pursue an MPOB licensee registration so the scraper can authenticate to
`prestasisawit.mpob.gov.my/en/sectoral` and pull the **official** Daily FFB
Reference Price. This requires:

1. CIO/XV sign-off on creating a licensee account.
2. Legal review of MPOB's terms-of-service for programmatic access.
3. Storage of credentials in GitHub Actions secrets (`MPOB_USERNAME`,
   `MPOB_PASSWORD`).
4. Failure-mode planning (account lockout, rate-limit, ToS change).

Tracked separately; this ADR explicitly does NOT authorize Track B.

## Consequences

### Positive
- **Pipeline runs again** \u2014 smallholders see fresh data after 16+ failed runs.
- **No regressions** to the core formula module (`mpob_bepi.py` math
  helpers unchanged; all v0.2 tests still pass).
- **Silent decay can't recur** \u2014 the workflow now auto-files a GitHub Issue
  on any failed run, with deduplication so it doesn't spam.
- **Honest labelling** \u2014 every payload, region, and (eventually) UI banner
  carries `is_indicative: true` and the `indicative_notice` text.

### Negative / Accepted risk
- Frontend currently does not yet render the "indicative" banner; a
  follow-up frontend PR will surface it. Until then, the JSON exposes the
  flag for any API consumer.
- The 0.93 share factor will drift if mill margin / transport assumptions
  change. Track B restoration is the durable fix.

## Implementation notes (this PR)

- New: `backend/scrapers/mpoc_cpo.py` \u2014 daily CPO from MPOC.
- New: `backend/scrapers/mpob_oer.py` \u2014 monthly OER from Prestasi Sawit API.
- Patched: `backend/scrapers/mpob_bepi.py` \u2014 graceful 404 handling; math
  helpers untouched.
- Rewritten: `backend/run_scraper.py` \u2014 new orchestration; back-compatible
  payload shape (`cpo`, `ffb`, plus new `oer` object).
- Patched: `.github/workflows/scraper_cron.yml` \u2014 Issue-on-failure step,
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
