# Reasoning Log: an offer against the reader's own usual (D30)

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026
**Related:** handoff `.macp/handoffs/20261113_SS_usual-price.md`

## What Alton approved, and what he deferred

- "D30 and D32 are also good." So D30 is built now.
- For D32 he asked for "further and concrete implementation after our current version stable and working well for others". SS reads that as: approved in principle, not to be started yet. Nothing was built or designed for it.
- "You might check for any feedbacks to us recently too" is his yes to open the response sheet, which SS reads only when he says so. It was read once, and only a count and dates are recorded here.

## What "stable and working well for others" can be measured by

- The only sign of other readers the project has is the feedback form. It holds two responses, the second of them Alton's own idea.
- So today there is no evidence either way about other readers. SS says this to Alton plainly: D32 needs growers to report prices, and that starts with growers using the app at all.

## D30: choices

- **The yardstick is the OER the reader's prices paid for, not the gap to the mill gate.** D30 was first worded as "RM 75 below the mill gate on average". That gap depends on the OER the dealer writes on the receipt, and D27 showed a low figure flatters it. The OER a price pays for needs no figure from the dealer, and the calculator already shows it for the offer.
- **The difference is given in ringgit a tonne.** "0.8% of OER" means little at the weighbridge. Multiplied by the price per 1% OER in use, it is "RM 35 a tonne", which a grower can say to a dealer.
- **The newest ten sales, by weight.** A habit should be recent, and a nine-tonne load says more about it than a half-tonne one.
- **At least three.** One or two sales are not a habit. With fewer, the calculator says nothing, which is better than a yardstick made from one receipt.
- **The same region only, when a region is chosen.** Prices and oil content differ between the Peninsula and Sabah and Sarawak. With a price typed by hand there is no region, so every sale counts.
- **It says where the figure comes from:** "From My Sales". A reader should know the app is reading their own records, on their phone, and nothing else.

## A limit worth knowing

- When MPOB's price falls and dealers have not yet followed, every offer looks above the reader's usual; when it rises, below. That is true, and it is the same lag the guide's fourth check describes. The line names the price per 1% OER it used, so the reader can see why.

## A risk checked

- The calculator now reads the journal, and the journal asks for `history.json`. Older calculator tests use a stand-in price service that doesn't answer that request. Flutter's test binding refuses real network calls with a 400, which the service treats as "no history". CI confirmed it: all 206 tests pass.
