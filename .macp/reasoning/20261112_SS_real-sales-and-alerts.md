# Reasoning Log: Alton's October sales, and repeat alerts (D25)

**Agent:** SS (Claude Code) · **Date:** 12 Nov 2026
**Related:** handoff `.macp/handoffs/20261112_SS_real-sales-and-alerts.md`

## What goes in this repo, and what doesn't

Alton's records name dealers and give his tonnages and income. `AGENTS.md` keeps personal data about smallholders, dealers and mills out of this repo. So the records, the per-sale table and the dealers' names stay on Alton's machine. The repo has only rates per tonne, percentages and counts, with dealers unnamed.

## How the sales were measured

- **MPOB's price:** the North column of MPOB's October PDF, read with the project's own parser. The sales were all in MPOB's North region.
- **The day:** the sale's date. Two sales were on Saturdays, when MPOB posts no price, so they use Friday's.
- **Dates:** Excel had stored six dates with day and month swapped (2 Oct as 10 Feb); the rest were text. Every date was read as day/month in October. This is an assumption, and a question for Alton.
- **Transport:** "included" was read as nothing taken off. Where a fee was given, it was divided by the tonnes and taken off the price. Also a question for Alton.
- **Mill-gate value:** MPOB's price times the OER on the receipt, rounded as the calculator rounds.
- **Verdict:** the app's rule: GREEN within 5%, AMBER to 15%, RED beyond.
- **Two sales had no OER** on the receipt. They are in the "pays for" figures, which need no OER, and out of the gap figures.

## What the figures can and can't carry

- **Can:** in this district in October, the four dealers that state an OER paid 6% to 10% below the mill gate at it, on average. The 5% band described one sale in 21.
- **Can't:** a dealer margin for the North, or for anywhere else. One grower, one month. Sabah and Sarawak may differ, and so may a month when prices fall.
- **The lag** (the price follows yesterday's MPOB price more than today's) rests on 13 sales to one dealer. It fits how the day runs, since MPOB publishes at noon. It is a lead, not a finding.

## Why not widen the band (D28)

- **For:** an app whose target is met once in 21 sales will look out of touch to the reader it is for.
- **Against:** GREEN at 10% tells every reader in the country that RM 85 below the mill gate is fair. D23 declined to show a made-up dealer margin for this reason: dealers could quote it back. One grower's month is better than a made-up figure, but it is still one district.
- **Chosen recommendation:** keep 5%, and give the reader figures that need no band: the gap in RM, and the OER the offer pays for (D27). Decide again when there are records from more growers (D29).

## Why "pays for X% OER" (D27)

Each dealer writes its own fixed OER, so a reader comparing two receipts compares two conventions. Price ÷ MPOB's price per 1% OER needs no receipt OER, uses only MPOB's figure and the offer, and puts every offer on one scale. MPOB's average OER for the region sits on the same scale, from the data the app already has.

## D25: comment, don't file again

- **Options:** file a second issue; comment on the open one; do nothing.
- **Chosen:** comment. GitHub notifies on a comment as it does on a new issue, and the history of one problem stays in one place.
- **Cost:** a problem that lasts comments on every run: up to about 4 a day for the scraper, 3 for the freshness watchdog, 1 a day or a week for the others. That is the point, but it is noisier than before. Closing the issue once the cause is known stops it.
- **Checked:** each of the five scripts was parsed by Node and run against a mock client. With an alert open it comments and files nothing; with none open it files as before.
