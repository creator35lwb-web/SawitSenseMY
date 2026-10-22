# Handoff: v0.3.17 verified; the estimate measured against MPOB's official price (K25); D22

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-23
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

Alton merged #37 and #38 and approved D21. He asked SS first to explain why the regions don't differ, and whether readers get valid, verified and accurate data.

**v0.3.17 verified live.**
- The merge's deploy (39826593603) succeeded, and `version.json` reads 0.3.17+19.
- At 360 px the card shows its two links and note, and no OER month or date, in EN, BM and 中文.

**What SS found while answering:**
1. **MPOB's official daily FFB reference price by region is public.**
   - It is published as a PDF at `https://price.mpob.gov.my/pdf/daily/ffb/<date>`: "MPOB Daily FFB Reference Price Summary by Region (Mill Gate) (RM/1% OER)", month to date, needing no login. The copy read had been updated 22 Oct at 12:00 pm.
   - The site's home page is a login page, but this endpoint isn't behind it.
   - palmoilpedia.mpob.gov.my has posted monthly regional reference prices.
   - ADR-001's premise that this data was behind a login applies only to the old BEPI pages.
2. **The estimate is off (K25).** Over the 15 October trading days, CPO × 0.01 × 0.93 compared with MPOB's figures as follows:
   - **Peninsula:** 5.9–10.8% below on every day, about 8% on average;
   - **Sabah:** 0.9–5.6% above;
   - **Sarawak:** 0.6% below to 4.0% above.

   The implied factor is about 1.01 in the Peninsula and 0.90–0.92 in East Malaysia. With the calculator's rule (GREEN within 5%), a Peninsula offer about 12% below MPOB's mill-gate price can show GREEN.
3. **Where 0.93 came from:** one dealer receipt (PV-85935, 17 Mar 2026) and a worked example from when CPO was about RM 2,624. It was never checked against MPOB, because MPOB's figures were thought to be private.
4. **Why the regions differ:** MPOB describes its figures as daily FFB transaction prices, published as a guide; it doesn't fix prices (parliamentary reply, 12 Mar 2015). They follow each region's market. SS found no public statement of MPOB's exact method and records none.
5. **MPOC served SS's machine a bot check**: "please wait while your request is being verified". GitHub's runs still read the table, but this may be what #33 saw. SS does not try to get past such checks.
   - Follow-up: add this page's wording to `_PAGE_HINTS` in `mpoc_cpo.py`, so the log names it.

**#39** is records only: PROJECT_STATUS (K25, D22, D21 on hold, v0.3.17 verified), an ADR-001 amendment, and this handoff and its reasoning log.

---

## Pending Items

- [ ] **Alton:** merge #39; decide D22, which SS recommends. Optionally tell MPOB, or ask it first, using the contacts listed on the PDF.
- [ ] **SS, if D22 is approved:**
  - **Data:** a scraper for MPOB's daily PDF, which needs a PDF text library added to the hash-locked lock. Checks on every figure, the last good prices kept (K7), and tests.
  - **App:** official regional prices with their date and a link; the banner and labels in EN, BM and 中文 (with a native check); a calculator note about dealer transport and margin.
  - **Records:** ADR-002.
- [ ] **SS, if D22 is declined:** build D21 as approved, and say in the banner and the method sheet how far the estimate has been from MPOB's price.
- [ ] **SS, next session:** confirm the first scheduled vulnerability watchdog run (Monday 26 Oct).
- [ ] **SS, mid-November:** October's OER.

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| Put D21 on hold and raise D22 | Relabelling a number now known to be up to 11% off would polish the wrong thing; MPOB's own figure is public | SS (Alton decides D22) |
| Record K25 now, in a records-only PR | The SSOT said MPOB's price was behind a login and had no record of the estimate's error | SS |
| State MPOB's method only as far as MPOB has stated it | No public MPOB source for the exact formula was found | SS |

---

## Blockers

None. D22 is Alton's call.
