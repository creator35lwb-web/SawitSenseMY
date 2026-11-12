# Handoff: MPOB's price history by region (D26, v0.5.0); why dealers' prices differ

**Agent:** SS (Claude Code) · **Date:** 12 Nov 2026 · **For:** Alton and the next SS session

## Asked
"Activate SS, PR #52 is merged." Alton also asked why the prices he is paid differ so much from MPOB's, and whether the app is of any use to a smallholder.

## Done
- **#52 (D25) is merged** and its deploy succeeded. No issues are open.
- **D26 built, in this PR, as v0.5.0.**
  - **Scraper:** every priced day of MPOB's monthly PDF is kept and merged into `history.json` as `ffb_days`. The month before is read once, while the history has no day of it.
  - **App:** the History tab opens on MPOB's price per 1% OER for a region: a chip for each region, a chart, and a table with each day's change. The CPO history is one tap away. EN, BM and 中文.
  - **Tests:** 24 new backend tests (227 pass). New frontend tests for the service, the axis and the tab; CI passed them.
  - **Seen before merging:** the preview build at 360 px in EN, BM and 中文. The switch at the top cut off its labels, and in BM two table headings touched; both are fixed in this PR and were checked again in a rebuilt preview.
- **MPOC's CPO price moved again** on 12 Nov (to 11 Nov's), after standing at 5 Nov for six days.

## Answer to Alton, in short
- The app's figures equal MPOB's PDF. The difference from what he is paid is real.
- MPOB's price is for fruit at the mill gate, per 1% of oil the mill gets. A dealer's price is for fruit at the farm or ramp, paid at once, with the dealer's transport, handling, risk and profit taken out, and with an OER figure that is the dealer's own, not a measurement.
- The app can't say what a dealer should pay. Its verdict called 20 of 21 ordinary sales AMBER, which gives nothing to act on.
- What it can help with, on the evidence of his own records: choosing between dealers on the day, seeing transport and OER figures for what they are, and seeing when the gap has grown.

## For Alton
- **The new BM and 中文 wording** in the History tab needs his read.
- **D30 (new):** measure an offer against the reader's own usual gap, with the journal (D29). SS recommends yes.
- **D27, D28 and D29** still wait, with the four questions about his records in the earlier 12 Nov handoff.

## Next
- After this PR merges, run the scraper once by hand, then check `history.json` and the History tab live in the three languages.
- D25 and K28 can only be checked when something next fails.
