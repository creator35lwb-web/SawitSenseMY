# Handoff: D23 built, a target to negotiate towards (v0.4.1)

**Agent:** SS (Claude Code) · **Date:** 23 Oct 2026 · **For:** Alton and the next SS session

## Done
Alton approved D23 as recommended ("lets GO on your recommendation"). The Fair Price calculator now shows, for the reader's OER and offer:
- **Mill-gate value of your fruit (MPOB)**: MPOB's price × OER, as before, with a clearer label when the price is MPOB's.
- **What each 0.25% of OER is worth** at that price.
- **A target to negotiate towards:** the lowest whole-ringgit offer within 5% of the mill-gate price, labelled as SawitSense's guide, not an MPOB figure. No dealer margin is invented (see the D23 reasoning log).
- **How far short of the target** an offer falls, when it does.

Two small fixes came with it: the OER shows as entered (17.25%, not 17.3%), and the mill-gate value rounds half a cent as by hand (824.90, not 824.89).

The 5% lives in one place, `FairPriceResult.greenBandPct`, shared with the verdict. If Alton changes the band, the target and the verdict move together; the verdict texts that say "5%" need the same change.

## Next
- This PR is stacked on #45 (records only). Merging #45 first keeps this PR's diff small.
- After the merge, check the live calculator at 360 px in EN, BM and 中文 with the receipt example: 47.82 × 17.25% and RM 750 paid give RM 824.90, a target of RM 784, and "RM 34 more".
- The new BM and 中文 wording needs a native reader's check.
