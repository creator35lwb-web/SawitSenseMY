# Handoff: v0.3.17, "Latest from MPOB" without the OER line (D20, K24); D21 raised

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-23
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0

---

## Context

Alton (23 Oct): the "Latest from MPOB" card's "OER for Sep 2026 … added on 12 Oct" could read as outdated or misleading. Should it mention no date?

**What SS found:**
- **The dates read as stale.** On the live site at 360 px, the badge at the top says "Updated 27 minutes ago". The card says "Sep 2026, added on 12 Oct", and in 中文 "于10月12日更新" ("updated on 12 Oct").
- **The line wasn't true (K24).**
  - The dashboard's price per 1% OER is CPO × 0.01 × 0.93, the same in every region. It doesn't use MPOB's OER.
  - MPOB's monthly OER appears only in "How is this calculated?", as each region's average (`indicative_oer_pct`).
  - So "These prices use MPOB's OER" was wrong from D18 (#31). SS wrote it from ADR-001's description of the method, not from what the cards show.

**#38 (v0.3.17+19):**
- **The card:** now its title, the two MPOB links and the note. The sentence is removed, not just its dates: without them it would still be untrue.
- **Removed code:** `MpobUpdatesCard.oerLine`, the card's `oer` parameter, `OerInfo.inAppSince`, and the strings `mpob_updates_oer` and `mpob_updates_oer_since` in EN, BM and 中文.
- **The OER month stays in "How is this calculated?"** (step 2 and its "choose Sep 2026" link), where it is used and can be checked. `sources_test.dart` already covers it.
- **The scraper is unchanged** and still writes `oer.in_app_since` to the open data. ADR-001 now says the app stopped showing it.
- **Tests (`mpob_updates_test.dart`):**
  - the card holds exactly its title, two links and note;
  - in EN, BM and 中文 it has no digit, no "OER" and no 出油率;
  - the links open MPOB's pages;
  - the Chinese note stays upright.
- **Not new wording:** nothing new for a native reader to check.

**Stacked on #37's branch** so the two `PROJECT_STATUS.md` updates don't conflict. Merge #37 first. If #38 merges first, it carries #37 along.

**D21 raised:** the same overstatement remains in two places.
- The banner says regional prices "are derived from MPOC daily CPO settlement and MPOB monthly OER".
- Every region card says "Source: Derived (MPOC CPO × MPOB OER)", untranslated in BM and 中文.

SS recommends saying the prices come from MPOC's daily CPO price, in the reader's language. Alton's call; the new BM and 中文 wording needs a native check.

---

## Pending Items

- [ ] **Alton:** merge #37, then #38; decide D21.
- [ ] **SS, after #38:** check v0.3.17 live at 360 px in EN, BM and 中文.
- [ ] **SS, next session:** confirm the first scheduled vulnerability watchdog run (Monday 26 Oct).
- [ ] **SS, mid-November:** October's OER: `oer.month` 10, `in_app_since`, and "How is this calculated?" shows October.

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| Remove the OER sentence, not only its dates | A date-free "These prices use MPOB's latest OER" would still be untrue (K24) | Alton raised it; SS recommends; merging #38 approves |
| Keep `oer.in_app_since` in the data | Removing a published open-data field could break someone's use of it, and keeping it costs nothing | SS |
| Raise the banner and source label as D21, not in #38 | They are the main disclaimer and every region card, with new BM and 中文 wording to check; Alton should decide | SS |

---

## Blockers

None.
