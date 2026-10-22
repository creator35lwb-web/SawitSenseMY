# Reasoning Log: checking the estimate against MPOB, 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** data accuracy investigation
**Related:** handoff `.macp/handoffs/20261023_SS_estimate-vs-mpob.md`, PR #39, K25, D21, D22, ADR-001

## The question behind the question

Alton asked why the regions don't differ, and whether readers get valid, verified and accurate data. Explaining the formula wasn't enough. The honest answer needed a measurement of how close the main number is to MPOB's.

## Steps

1. **Where 0.93 comes from.** ADR-001 anchors it on PV-85935, a dealer receipt (17 Mar 2026, RM 42.77 per 1% OER), and a worked example (CPO about RM 2,624 → RM 24.40). Neither is a check against MPOB's own reference price.
2. **Looking for MPOB's figures.** A search surfaced `price.mpob.gov.my/pdf/daily/ffb/2021-10-31`.
   - The same path for 2026-10-21 returned MPOB's October 2026 daily summary, with no login.
   - The site's home page is a login page ("Sistem eReg Bepi"), but search engines have indexed these PDFs since at least 2021, so they are publicly reachable. Whether MPOB means them to be reused is part of D22.
   - palmoilpedia.mpob.gov.my, MPOB's portal, has posted the monthly regional prices.
3. **Measuring the estimate.** SS compared it with MPOB on the 15 trading days where `history.json` has MPOC's CPO price. The estimate is exactly what SawitSense published: CPO × 0.01 × 0.93, rounded to sen.
   - **Result:** the Peninsula was lower every day (5.9–10.8%); Sabah and Sarawak were mostly higher.
   - **Implied factor:** about 1.01 and 0.90–0.92 respectively.
4. **Effect on readers.** With the verdict rule (GREEN within 5%, AMBER to 15%), the Peninsula bias makes the calculator lenient. It can call an offer about 12% below MPOB's mill-gate price "fair".
5. **What MPOB says its price is.** A 2015 parliamentary reply says MPOB doesn't fix FFB prices, but publishes daily FFB transaction prices as a guide. The exact method wasn't found in any public source, so the records don't state one.
6. **Reuse.** MPOB's disclaimer has no reuse terms, only © MPOB and a limit on its liability. Showing MPOB's figures with attribution and a link is the honest form. Telling MPOB, or asking first, is Alton's call.

## Why D22, and why D21 waits

- **D21** only relabels the estimate. Once its error is known and the official figure is public, the right fix is to show MPOB's figure: verifiable against MPOB's own PDF, regional, and the benchmark the tool was designed around (Price/mt = MPOB Price_1% × graded OER).
- **D21 still stands if D22 is declined.** In that case the banner should also say how far the estimate has been from MPOB's price.

## Trust in sources

- PDFs and web pages were read as data.
- SS didn't follow links from a summary that reported unrelated spam links in palmoilpedia's footer, and wouldn't link readers to that portal.
- MPOC's bot check was not bypassed.
