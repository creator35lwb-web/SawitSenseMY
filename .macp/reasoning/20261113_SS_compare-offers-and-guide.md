# Reasoning Log: compare dealers' offers (D27) and the guide (D31)

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026
**Related:** handoff `.macp/handoffs/20261113_SS_compare-offers-and-guide.md`

## What "valuable information for others" can honestly be

- **Not Alton's figures.** One grower's month in one district isn't what dealers pay elsewhere. Shown in the app, "about 9% below MPOB" would become the going rate in readers' minds, and a ceiling in dealers' mouths (D23).
- **The method that produced them.** The month showed three places where an offer misleads: transport, the OER figure, and timing. Each can be turned into something any reader can do with their own offer. That is D27 (the sum) and D31 (the checks).
- **What dealers nearby pay** can only come from other growers. That is D32, and SS still recommends waiting.

## D27: choices

- **The verdict uses the price kept.** `paidPrice` now means the quoted price less transport, so the gap, the verdict and "short of the target" all follow without further change. `quotedPrice` and `transport` are kept only to show the sum.
- **Transport with no price is ignored,** and transport that takes the whole price is refused in the form. Neither can produce a verdict from nothing.
- **"Pays for X% OER" is shown to one decimal.** Dealers' prices move in RM 10 steps, which is about 0.2% of OER, so a second decimal would be false precision.
- **The line names no source for the price.** In the calculator the price per 1% OER can be typed by hand, so the line says "this price pays for", not "at MPOB's price". The sum beneath it shows which price was used. The verdict wording follows the same rule.
- **MPOB's regional average sits beside it only when a region is chosen.** With a typed price there is no region to take it from.
- **The existing dealer note stays above it,** so a reader who sees 17.5% against the mills' 19.70% also reads that dealers usually pay less, for transport and margin.

## D31: choices

- **Round figures in the example** (RM 790 less RM 25, against RM 770), not a receipt's. The lesson is the same and no dealer could recognise a sale.
- **The fourth check is worded from what the month showed, no further.** One dealer's price followed the day before's MPOB price with a correlation of 0.59 over 13 sales. That is too thin to tell readers "dealers follow MPOB a day late". What the month does show: MPOB's price rose and the dealers' stayed about the same. So the check says to look at the History tab and ask for more when MPOB has risen.
- **A test guards the limit.** It fails if any guide text states a percentage below MPOB's price, in any of the three languages.
- **The link sits under the transport field,** above the Calculate button: the place a reader is when holding an offer.

## What the preview caught that the tests couldn't

- The transport label was cut off at 360 px in EN and BM. Tests pass with cut-off text. "Optional" moved to the helper line in all three languages, for consistency.
- The region's average broke before its last word. It was reworded so that a break falls inside the bracket: "North mills averaged 19.70% OER (MPOB, Oct 2026)".
- In BM the "pays for" title broke before "OER", and in 中文 the transport sum broke before its last number. Both were shortened.

## One branch on top of another

#54 (records) was still open when Alton said yes, so this branch starts from it. Merging #55 brings #54's commits, and GitHub will then show #54 as merged. That is one merge for Alton, not two.
