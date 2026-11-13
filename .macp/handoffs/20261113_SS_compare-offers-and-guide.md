# Handoff: v0.6.0 in review — compare dealers' offers (D27) and four checks before accepting a price (D31)

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026 · **For:** Alton and the next SS session

## Asked
"The live page is good. But now the key is how do we provide valuable information for others who are needed this data." Alton also corrected the transport reading (see `20261113_SS_v0.5.0-verified.md`), and said yes to D27 and D31 when SS asked.

## Done, in #55
- **D27, in the calculator:**
  - a new optional field, "Transport taken off (RM/tonne)". When it is filled, the verdict, the gap and the target use what the reader keeps, and the result shows the sum;
  - a new line, "This price pays for X% OER", with the sum beneath it and MPOB's average OER for the chosen region beside it. It doesn't depend on the OER a dealer names.
- **D31, the guide "Before you accept a price: 4 checks",** opened from the calculator, in EN, BM and 中文:
  1. is transport inside the price;
  2. the OER a dealer names is an offer;
  3. ask a second dealer the same day;
  4. watch whether MPOB's price has moved.
- **Version 0.6.0.** `CHANGELOG.md` has the entry.
- **Tests:** 16 new in `frontend/test/offer_test.dart`. CI passes: backend 227, frontend 139.
- **Seen in the preview build at 360 px** in EN, BM and 中文, with live prices. A cut-off label and three badly wrapped lines were found there and fixed.

## Not done
- The live site still runs v0.5.0 until #55 merges.
- The Malay and Chinese wording has had no native reader yet.

## For Alton
1. **Read the BM and 中文** of the guide and the new calculator lines; the PR lists where they are. Then merge #55. It carries #54's records, so #54 needs no separate merge.
2. **The guide gives no figure for how far below MPOB's price dealers pay.** Your records say about 9%, but shown in the app it would read as the going rate, and a dealer could quote it back (D23). Say if you want it in.
3. **Still waiting for your yes:** D29 (sales journal on the phone), D30 (your own usual gap as the yardstick), D32 (other growers' prices; SS recommends not yet), D28 (keep the 5% band).

## Next
- After the merge: check v0.6.0 live at 360 px in three languages, and that the footer reads v0.6.0.
- Each trading day should add one entry to `ffb_days`.
