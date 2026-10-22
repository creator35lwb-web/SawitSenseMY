# Handoff: v0.4.0, MPOB's official daily FFB reference price (D22, K25)

## Status: IN_PROGRESS

**From:** SS (Claude Code), CTO & Lead Maintainer
**To:** Alton (Founder, Human Orchestrator), and the next SS session
**Date:** 2026-10-23
**Project:** SawitSenseMY
**Genesis Version:** SS (Claude Code) Genesis v1.0 (v1.1 in its own PR)

---

## Context

Alton merged #39 and approved D22: SawitSense shows MPOB's own price. He also asked:
- that "Latest from MPOB" keep a current link to MPOB's daily FFB price PDF;
- that SS update its Genesis master prompt to v1.1 (separate PR).

**#40 (v0.4.0+20):**

- **Scraper (`backend/scrapers/mpob_ffb.py`):**
  - Reads `https://price.mpob.gov.my/pdf/daily/ffb/<date>` with the standard library. The PDF's text is positioned strings in one Flate stream, and the table is rebuilt from their positions.
  - Checks the title, month, column order, every cell (a price or NT/PH) and the RM 10–200 range. Anything unexpected rejects the document.
  - Uses last month's PDF early in a month. On a regional holiday, a region keeps its earlier price and date.
  - Reads MPOB's update time and the Sarawak footnote ("Miri & Bintulu").
  - Never logs the document's text.
- **Pipeline (`backend/run_scraper.py`):**
  - The `ffb` block is MPOB's, with `avg_oer_pct` from MPOB's monthly OER, and `formula_status` is `OFFICIAL`.
  - If MPOB can't be read, the last `ffb` block is carried forward with its date and a warning (K7).
  - Warnings on a fresh read: older than 6 days, outside 0.8–1.2 × CPO × 0.01, or a changed Sarawak note.
  - The estimate is removed. A pre-D22 snapshot keeps its indicative label until MPOB is read.
- **App:**
  - **Region cards:** "Source: MPOB, at the mill gate" in EN, BM and 中文, Sarawak with "Miri and Bintulu", and a region's own date when it differs.
  - **Under the prices:** a dated link to MPOB's PDF, the dealer note, and "Where do these prices come from?" (the official form of the method sheet).
  - **"Latest from MPOB":** links first to MPOB's PDF.
  - **Calculator:** the method link, and the dealer note under the verdict.
  - An older indicative snapshot still renders as before.
- **Tests:**
  - backend: 25 for the parser and scraper, with synthetic PDFs in MPOB's layout (the repo holds no copy of MPOB's PDF, which lists staff emails), plus the pipeline tests rewritten; 175 pass, flake8 clean;
  - frontend: `official_prices_test.dart` added and `mpob_updates_test.dart` updated, run by CI because Flutter isn't installed locally.
- **Live check before the PR:** the scraper read MPOB's real PDF in 0.6 s. It got the 22 Oct prices for all six regions and the 12:00 pm update time, with no warnings.
- **Records:**
  - ADR-002, with ADR-001 marked superseded in part;
  - AGENTS.md (core formula, key files), README, CHANGELOG [0.4.0];
  - PROJECT_STATUS: K25 and K10 fixed, D21 superseded, D22 built.

---

## Pending Items

- [ ] **Alton:** merge #40 and the Genesis v1.1 PR. Optionally tell MPOB.
- [ ] **SS, after #40:**
  - check v0.4.0 live at 360 px in EN, BM and 中文;
  - confirm the first scraper run writes `OFFICIAL` with no warnings, then verify the live prices against MPOB's PDF.
- [ ] **Native reader (optional):** the new BM and 中文 strings in `frontend/lib/l10n/` (ffb_official_source, source_mpob, dealer_note, method_*_official, mpob_ffb_pdf).
- [ ] **SS, next session:** the first scheduled vulnerability watchdog run (Monday 26 Oct).
- [ ] **SS, mid-November:** October's OER.

---

## Decisions Made

| Decision | Rationale | Approved By |
|----------|-----------|-------------|
| Parse the PDF with the standard library, not a PDF package | Its text is plain positioned strings; no new package in the hash-locked supply chain | SS |
| Reject the whole document on anything unexpected | A misread price is worse than yesterday's correct one (K7) | SS |
| Keep requiring a CPO price to publish | Unchanged K7 rule, and the day files are keyed by the CPO date. Revisit if MPOC's bot check starts blocking GitHub's runners | SS |
| Keep the verdict thresholds; add the dealer note | Changing what "fair" means needs data on dealer margins, which SawitSense doesn't have | SS (flagged to Alton) |
| Version 0.4.0 | The data source changed, not just wording | SS |

---

## Blockers

None.
