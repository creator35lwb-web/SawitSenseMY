# Handoff: health check 24 Oct – 12 Nov; MPOC must not hold back MPOB's prices (K28)

**Agent:** SS (Claude Code) · **Date:** 12 Nov 2026 · **For:** Alton and the next SS session

## Asked
"Activate SS, lets get latest performance of our SawitSenseMY."

## Found
- **The site is up and correct.** v0.4.2 is live. MPOB's prices for 11 Nov on the site equal MPOB's PDF exactly, with no warnings.
- **Runs since 23 Oct:** scraper 75 of 77, deploys 76 of 77, and every watchdog run passed (freshness 57, feedback form 20, vulnerability 3).
- **Freshness, 24 Oct – 12 Nov:** 83% GREEN, 15% AMBER, 1.4% RED. Mornings were 98% GREEN and never RED. Up to 1 Nov it was 92% GREEN with no RED; from 2 Nov, 76% GREEN and 2.6% RED.
- **Both RED spells have one cause (K28).** MPOC answered with its bot check on Sat 7 Nov and Tue 10 Nov. A run with no CPO price published nothing, although it had read MPOB's prices. On 10 Nov, MPOB's prices for the day reached the site at 20:32 MYT, 8.5 h after MPOB's noon update.
- **The 10 Nov failure told nobody.** #50 from 7 Nov was still open, and the alert step skips filing while an alert is open (D25).
- **Issue #49** was GitHub Pages: a deploy sat at "updating_pages" for 10 minutes. The next deploy succeeded.
- **MPOB's October OER arrived on 10 Nov** and is live (Malaysia 20.34%).
- **MPOC's CPO price has stood at 5 Nov since 6 Nov.** MPOC's own page ends there.
- **D24 is live** in EN, BM and 中文. K26 (month start) and K27 (link date) both held in real conditions.
- **Speed is unchanged** from 1 Oct: 15.5 s on Lighthouse's slow-phone test, 4.1–4.8 s on good 4G, 2.91 MB on a first visit, 1–2 s on a return visit.
- **Security:** 0 Dependabot alerts, 0 OSV findings, SonarCloud gate passed with all ratings A.

## Done
- **K28 fixed in this PR.** A run that read MPOB's prices now publishes them, keeps the last CPO price with its date (`cpo.carried_forward`), and still raises the alert. A run that read neither source publishes nothing, as before.
  - 6 new tests; 193 backend tests pass; flake8 clean.
  - A dry run with MPOC forced unreadable and MPOB read for real gave MPOB's 11 Nov prices, the 5 Nov CPO price carried forward, one warning naming MPOC, and exit 0. Nothing was written.
- **#49 and #50 closed** with what was found, so new alerts can be raised again.
- `PROJECT_STATUS.md` has the health check, the new performance table, K28, D25 and D26.

## For Alton
- **D25:** a repeat failure should comment on the open alert issue, so it notifies again. SS recommends yes.
- **D26:** a 30-day history of MPOB's price per region, from MPOB's own PDF. The History tab is CPO-only and ends on 5 Nov. SS recommends yes, as the next app change.
- **Feedback sheet:** SS did not read it this session. Say yes and SS will summarise any new responses.

## Next
- After this PR merges, run the scraper once by hand and check it is green with no warnings.
- The fix only acts when MPOC can't be read. When that next happens, check that MPOB's prices went out and the alert named MPOC.
- Watch MPOC's CPO date move past 5 Nov.
- MPOB's November OER is due around 10 December.
