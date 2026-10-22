# Reasoning Log: switching to MPOB's official daily price, 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** data source change (D22)
**Related:** handoff `.macp/handoffs/20261023_SS_mpob-official-prices.md`, PR #40, ADR-002, K25, D21, D22

## Reading the PDF without a new package

- The supply chain is 17 hash-locked packages, wheels only, so a PDF library would be a real cost.
- Decompressing the PDF's streams with `zlib` showed:
  - one Flate content stream, with Helvetica (a base font, no embedding);
  - every cell is a `BT x y Td /F2 6 Tf [(text)] TJ ET` string.
- Grouping strings by `y` and sorting by `x` rebuilt the table exactly, for both October 2026 and October 2021. The format has been stable for five years.
- A small tokenizer handles PDF string escapes, including the `\(...\)` in "(Ministry of Plantation and Commodities)".

## What can go wrong, and what happens

| Case | Behaviour |
|------|-----------|
| MPOB down | 3 tries, then no read; last month's PDF isn't tried, because it's on the same server (K23). The last prices are kept with a warning |
| 404 or no prices yet this month | Last month's PDF, so the 1st of a month needs no alert |
| A login page or another document | Rejected: "isn't a PDF" or the title check. The log gives size and URL, never the text |
| Columns reordered, a cell misread, a price out of range | The whole document is rejected; the last prices stay |
| A holiday in some regions only | Those regions keep their earlier price and date, and the app shows the date |
| MPOB stops updating | A warning once the latest price is more than 6 days old |
| A price far from CPO | A warning outside 0.8–1.2 × CPO × 0.01. October ran 0.88–1.04 |

## Why the verdict thresholds stay

GREEN within 5%, AMBER to 15%, RED below.
- Against the mill-gate price, a dealer's usual deduction for transport and margin may land in AMBER. SawitSense has no data on what is normal.
- So the app says plainly that dealers usually pay less, and the thresholds wait for evidence, such as feedback or receipts.
- Flagged to Alton in the PR.

## The transition

- After the merge, the deploy publishes the new app before the next scraper run writes MPOB's prices. In between, the app shows the old indicative snapshot, still with its banner and labels: both forms render.
- If MPOB can't be read on that first run, the indicative block is carried forward with its label and an "earlier estimate" notice, never mixed with official labels.

## Not committed

- MPOB's real PDF stays out of the repo, because it lists staff email addresses. The tests build PDFs in its layout.
- The live check used the real PDF in memory only.
