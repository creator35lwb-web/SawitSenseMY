# SawitSense Ethical Operating Framework v1.1

## Hierarchy

1. **Safety** — Never endanger smallholders through bad data or privacy leaks
2. **Data Integrity** — Only use verified formulas (MPOB official). Reject unverifiable calculations. Indicative values are allowed only under the Path C exception below.
3. **Transparency** — Always show data source, timestamp, and freshness. Never present estimates as facts. Never show demo or synthetic prices as if they were real.
4. **Privacy** — Sales Journal data local-first. Cloud sync opt-in only. No admin access to individual records.
5. **Fairness** — Serve all smallholders equally regardless of acreage, region, or language.
6. **Accessibility** — Offline-first. Mobile-responsive. Multi-language (BM, EN, CN).

## Specific Rules

- MPOB FFB Reference Price is the ONLY authoritative benchmark
- **Path C exception** ([ADR-001](../docs/ADR-001-mpob-data-source-change.md)). Alton approved this on 21 May 2026; it was recorded here in v1.1. While MPOB's Daily FFB Reference Price is unavailable to the public, an indicative Price_1% may be derived as `CPO × 0.01 × 0.93` from official public sources (the MPOC CPO settlement and MPOB OER). It must:
  - be labelled `is_indicative: true` in the data
  - be shown with a visible banner
  - never be presented as the MPOB price
  - end once the MPOB price is available again
- OER grading assigned by dealers must always be shown alongside MPOB benchmark for comparison
- The rejected unofficial dealer formula (CPO x 0.2? x 0.7?) must NEVER be implemented
- Demo, sample or synthetic prices must never be shown in the app. When real data can't be loaded, say so.
- Community-contributed data (Module 5) must use median, not mean, to resist manipulation
- All dealer names in community layer must be hashed, never stored in plaintext
- Data freshness must always be visible: GREEN (<6h), AMBER (6-12h), RED (>12h). Show the age in words and the time of the last update, so that data from the last trading day (e.g. at weekends) is clear.

## Authority

- **Alton (Human Orchestrator)** has absolute authority over all ethical decisions
- AI agents operate under delegated authority only

## Changelog

- **v1.1 (30 Sep 2026):**
  - Recorded the Path C indicative exception (approved 21 May 2026).
  - Banned demo or synthetic prices in the app.
  - Freshness is now shown with the age in words.
  - Decisions D1–D3 by Alton on 30 Sep 2026. Drafted by SS (Claude Code); in force when merged.
- **v1.0 (12 Apr 2026):** Initial framework.
