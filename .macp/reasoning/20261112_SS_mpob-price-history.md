# Reasoning Log: MPOB's price history (D26), and what the app is for

**Agent:** SS (Claude Code) · **Date:** 12 Nov 2026
**Related:** handoff `.macp/handoffs/20261112_SS_mpob-price-history.md`

## D26: where the history comes from

- **Fact:** MPOB's PDF for a month has a row for every day, with all six regions. The scraper already downloads it every run and used only the last priced row.
- **Options:**
  1. **Keep every row of the PDF just read, and merge it into `history.json`** (chosen). No new request in a normal run. A day MPOB adds or corrects later is picked up, because the whole month is read again each run.
  2. **Build the history from the dated snapshot files.** They are filed under the CPO date, so several days of MPOB's prices overwrite one file while MPOC is behind. 6 and 10 Nov would be missing.
  3. **Fetch two months of PDFs every run.** It doubles the requests to MPOB for a month that no longer changes.
- **The month before** is read once, while the history holds no day of it. This fills the first run and repairs a gap. It gets one attempt, because the history can wait for the next run and the job has a 10-minute limit (K23).
- **Not covered:** a price MPOB adds to last month after this month's first price is up. It hasn't been seen; 26 Oct was added within October.

## D26: the tab

- **Opens on MPOB's price,** because that is the price the dashboard and the calculator use. CPO stays, one tap away.
- **A data file with no MPOB days** shows the CPO history alone, with no switch, so the app and the data can be deployed in either order.
- **Region chips, not a menu:** one tap, and all six are visible at 360 px in two rows.
- **The change column is grey,** not red and green. Colour in this app means a verdict, and a falling price isn't one.
- **Gridlines:** MPOB's price moves by cents, so the axis needs steps below RM 10. CPO's axis is unchanged: its smallest step stays RM 10.
- **No region is remembered** between visits. Browser storage holds the language only (`AGENTS.md`).

## What the preview showed

Flutter isn't installed here, so the code was first compiled by CI. Its tests passed. The preview build then showed what tests didn't: the switch's labels wrapped at 360 px and were cut off. Kept to one line, the longer label still lost its last letter, so the switch now spans the width, half each. In BM the table's last two headings touched; the columns were rebalanced. Each fix was checked in a rebuilt preview.

## Why dealers' prices differ from MPOB's

Alton asked. What is fact, and what is inference:

- **Fact:** the site's prices equal MPOB's PDF. His 21 graded sales were 2% to 11% below MPOB's price at the receipt's OER.
- **Fact:** MPOB's figure is a mill-gate price per 1% OER. It says so in its title.
- **Fact:** each dealer wrote one fixed OER on every receipt.
- **Inference:** the gap pays for the dealer's transport to the mill, handling, the risk on weight and grading, paying at once, and profit. This is how the trade is usually described; SS has no figures for any of the parts.
- **Inference:** since the receipt's OER isn't measured, the gap "at the receipt's OER" could overstate or understate the real one. The records can't settle it.
- **Not claimed:** that the dealers underpay. The records don't show it, and SS found no published margin to compare with (D23).

## What the app is for, after this

- The verdict answers "is this offer near the mill-gate price?". For a dealer sale the answer is always no, by about the same amount. A reader learns nothing from the twentieth AMBER.
- The questions a smallholder can act on are narrower: which dealer today, is this offer worse than my usual, and has MPOB's price moved since the dealer last changed his.
- Each can be answered from MPOB's figures and the reader's own, with nothing made up: D27 (offers on one scale, transport off), D26 (the trend), D29 (the reader's sales), D30 (the reader's usual gap as the yardstick).
- **Why not widen the band instead (D28):** it would turn AMBER into GREEN without telling the reader anything new, and would publish a "fair" discount that rests on one grower.
