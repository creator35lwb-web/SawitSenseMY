# Handoff: #51 verified; repeat alerts (D25); Alton's October sales against MPOB's price

**Agent:** SS (Claude Code) · **Date:** 12 Nov 2026 · **For:** Alton and the next SS session

## Asked
"Activate SS, PR #51 is merged." Alton shared his October sales records to investigate, asked for #49 and #50 to be closed, and agreed D25 and D26.

## Done
- **#51 (K28) verified.** The first scheduled run on the merged code (43128321773) was clean, and its deploy succeeded.
- **#49 and #50 closed**, each with a comment on what was found.
- **D25 built, in this PR.** In all five alert steps, a failure while an alert issue is open now comments on that issue with the run's link.
  - Each script was run against a mock GitHub client, with and without an open alert, and did the right thing in both cases.
  - 10 new workflow tests; the backend suite passes.
- **Alton's October sales measured against MPOB's price.** The records are private. Only figures without names or amounts are in `PROJECT_STATUS.md`.

## Found in the sales records
- Dealers paid a median RM 77 a tonne (9.2%) below MPOB's mill-gate price at the receipt's OER.
- The app called 1 sale GREEN and 20 AMBER. The target (D23) was reached once in 21 sales.
- The OER on a receipt is one fixed figure per dealer, so it can't be compared across dealers.
- The price divided by MPOB's price per 1% OER can be compared. It was 15.7% to 16.8% across the sales; MPOB's average for mills in the North was 19.70%.
- One dealer charged transport separately, which took most of its higher price.
- Dealers' prices moved in RM 10 steps and followed MPOB slowly, so the gap grew as MPOB's price rose.

## For Alton
- **D27:** a transport field in the calculator, and a line that turns any offer into "pays for X% OER". SS recommends yes, after D26.
- **D28:** keep the 5% band for now. SS recommends not widening it on one grower's month.
- **D29:** a sales journal on the phone. SS recommends yes, after D27, with no dealer names. It needs a decision on browser storage.
- **Four questions about the records:**
  1. Six dates had been turned round by Excel (2 Oct stored as 10 Feb, and so on). SS read every date as day/month in October. Is that right?
  2. "Included" under transport: is the price on the receipt what was paid, with nothing taken off?
  3. For the dealer that charged transport, was the fee taken off the payment? SS assumed so.
  4. Is the OER on a receipt what the dealer always writes, or a grade of that load?

## Next
- **D26** (approved): a 30-day history of MPOB's price per region, for v0.5.0. It is the next PR.
- D25 and K28 only act when something fails, so they can't be shown on demand. Check them the next time an alert opens.
