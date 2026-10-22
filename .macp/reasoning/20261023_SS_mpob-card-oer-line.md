# Reasoning Log: the OER line on "Latest from MPOB", 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** UX and accuracy fix, from Alton's report
**Related:** handoff `.macp/handoffs/20261023_SS_mpob-card-oer-line.md`, PRs #31 and #38, D18, D20, D21, K24

## Look before deciding

- Live screenshots at 360 px, in EN, BM and 中文, of the top of the dashboard and of the card. Beside "Up to date · Updated 27 minutes ago", the card's "Sep 2026, added on 12 Oct" reads as a stale corner of the page.
- Before choosing between "no dates" and "explain the dates", SS checked what MPOB's OER actually feeds:
  - the region cards show `price_1pct_oer`, RM 44.33 everywhere, which is CPO × 0.01 × 0.93;
  - `indicative_oer_pct` is shown only in the method sheet;
  - `indicative_fair_price_per_tonne` is shown nowhere;
  - `git log -S` confirms no widget ever displayed the per-tonne figure.
- So the sentence was untrue as well as confusing.

## Options weighed

| Option | Why not, or why |
|--------|-----------------|
| Drop only the dates: "These prices use MPOB's latest OER." | Still untrue: these prices don't use it |
| Explain the cadence: "MPOB publishes OER monthly; the newest is September" | Accurate about MPOB, but still ties the dashboard's prices to OER, and adds new BM and 中文 wording |
| **Remove the sentence; keep the links** | Nothing dated, nothing untrue, no new wording. The month remains where it is used (method sheet step 2) and where readers check it on MPOB's page |

## What stays and why

- **`oer.in_app_since` in the data.** It is documented open data (ADR-001), and removing a published field could break someone's use of it. The scraper code is small and tested.
- **The month in the method sheet.** It belongs there: step 2 is MPOB's regional averages, and its link says which month to choose on MPOB's page.

## Why D21 is separate

The banner ("derived from MPOC daily CPO settlement and MPOB monthly OER") and the region source label ("Derived (MPOC CPO × MPOB OER)") overstate OER's role the same way. They aren't dated, though, so they don't cause Alton's "outdated" confusion. Changing them means:
- rewording the main disclaimer;
- localising a label that is English in every language today;
- new BM and 中文 text that a native reader should check.

That is a decision for Alton, not something to slip into a fix he asked for.

## Mistakes caught

| Thought | Caught when | Corrected to | Lesson |
|---------|-------------|--------------|--------|
| D18's line: "These prices use MPOB's OER" (17 Oct) | Alton questioned the dates; tracing what the cards display showed OER isn't in them | Removed the line (K24) | Describe what the screen shows, from the code that draws it, not from the method's summary in an ADR. |
