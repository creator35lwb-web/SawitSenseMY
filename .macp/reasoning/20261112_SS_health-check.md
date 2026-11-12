# Reasoning Log: health check, 2026-11-12, and K28

**Agent:** SS (Claude Code) · **Session type:** routine check, one fix
**Related:** handoff `.macp/handoffs/20261112_SS_health-check.md`

## How the figures were measured

- **Freshness:** the age of the newest commit that changed `backend/data/latest.json` on `main`, sampled each minute from 24 Oct 00:00 MYT to 12 Nov 07:49 MYT. GREEN is under 6 h, AMBER 6–12 h and RED 12 h or more (D1).
  - Earlier checks used the newest data commit of any kind. A failed run still commits `health.json`, which would have hidden both RED spells, so this check counts only commits that changed the prices file.
  - It understates the age on the live site by the deploy time, about 3 minutes.
- **MPOB's price on the site:** for each trading day, the time of the first commit whose `ffb.date` is that day, less 12:00 MYT. MPOB's PDF always says "Last update 12:00 pm", so MPOB's real publishing time isn't known more exactly than that.
- **What each run read:** the logs of all 77 scraper runs, searched for the MPOC and MPOB lines.
- **Speed:** headless Chrome through puppeteer-core, 412 px wide, CPU slowed 4×, with Lighthouse's mobile network (1.6 Mbps, 150 ms) and a good-4G network (9 Mbps, 60 ms). Three first visits per profile, each in a fresh browser context, then a reload. "App and prices on screen" is the later of Flutter's `flutter-first-frame` event and the end of the `latest.json` request. Sizes are the bytes on the wire.
  - One good-4G run took 12 s to get its first byte. The other two were normal, so it is reported as an outlier, not averaged in.
- **Frontend tests:** Flutter isn't installed here. The count of about 113 comes from the test files; CI last ran them on 23 Oct.

## K28: why a missing CPO price stopped MPOB's prices

- **Facts:**
  - `decide_payload` returned None when there was no CPO price, before looking at anything else. The rule is K7's, from 30 Sep, when the price per 1% OER was CPO × 0.01 × 0.93: without CPO there was no price to publish.
  - Since D22 (23 Oct) the prices are MPOB's own. The CPO price is shown on its own card and used for one sanity check.
  - Both failed runs logged MPOB's prices, read correctly, a few seconds before giving up.
- **Inference:** the rule outlived its reason. It wasn't revisited in #40 because MPOC had been the reliable source and MPOB the new one.

## Options

1. **Publish MPOB's prices and carry the last CPO price forward** (chosen). It matches what the code already does for OER and for MPOB's prices: keep the last figure, marked `carried_forward`, with a warning. The warning makes the workflow raise its alert, so MPOC's trouble is still reported.
2. **Publish with no CPO price.** The CPO card would go empty for a few hours for no gain; the last price with its date is more useful and just as honest.
3. **Retry MPOC longer.** Both bot checks outlasted two retries 30 s apart. Waiting longer risks the 10-minute limit (K23) and still leaves MPOB's prices waiting on MPOC.
4. **Get past the bot check.** Not considered. SS doesn't work around a site's bot checks.

## What stays the same

- A run that read neither MPOC nor MPOB still publishes nothing. Publishing would reset the freshness badge to "Up to date" when nothing had been checked.
- A read of MPOB that is older than the prices shown still counts as no read (K26), so with no CPO price that run publishes nothing too.
- The app needs no change: it ignores `cpo.carried_forward` and shows the CPO price with its own date, as it does today while MPOC is behind.

## Closing #49 and #50

Both issues say to close them once the next run succeeds, and both conditions were met days ago. While #50 stayed open, the 10 Nov failure raised nothing. Closing them, with what was found, lets the next failure raise an alert. Making a repeat failure notify by itself is D25, for Alton.

## Not done, and why

- **D25 and D26** change the alerting behaviour and the app, so they go to Alton.
- **History gaps** (23 and 28 Oct missing from the CPO history) would be covered by D26's rework, so no separate patch.
- **The feedback sheet** was not read; it needs Alton's yes each time.
