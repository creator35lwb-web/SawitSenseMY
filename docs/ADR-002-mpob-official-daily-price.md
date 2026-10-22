# ADR-002: MPOB's official daily FFB reference price (D22)

- **Status:** Accepted
- **Date:** 2026-10-23
- **Author:** SS (Claude Code), CTO & Lead Maintainer
- **Decision:** D22, approved by Alton on 23 Oct 2026
- **Supersedes:** the indicative estimate of [ADR-001](ADR-001-mpob-data-source-change.md) (Track A)

## Context

- **What ADR-001 assumed.** In May 2026 ADR-001 believed MPOB's Daily FFB Reference Price was behind a licensee login. So SawitSense showed an estimate: MPOC's daily CPO price × 0.01 × 0.93, the same for every region.
- **What turned out to be true.** On 23 Oct 2026 SS found MPOB's "Daily FFB Reference Price Summary by Region (Mill Gate) (RM/1% OER)" published as a PDF that needs no login:
  - the address is `https://price.mpob.gov.my/pdf/daily/ffb/<date>`;
  - each copy holds the month to date, updated each trading day;
  - search engines have indexed these PDFs since at least 2021.

  Only the old BEPI pages are behind the login.
- **How far off the estimate was (K25).** Over the 15 October 2026 trading days:
  - **Peninsular regions:** 5.9–10.8% too low on every day;
  - **Sabah:** 0.9–5.6% too high;
  - **Sarawak:** from 0.6% too low to 4.0% too high.

  So the Fair Price verdict could call a Peninsular offer about 12% below MPOB's mill-gate price fair.
- **Where 0.93 came from.** It rested on one dealer receipt and an old worked example, and had never been checked against MPOB.

## Decision

SawitSense shows MPOB's own daily price per 1% OER for each region, as MPOB publishes it.

- **Source.** `backend/scrapers/mpob_ffb.py` reads MPOB's PDF with the standard library.
  - Its text sits in a Flate-compressed stream as positioned strings, and the table is rebuilt from their positions.
  - No PDF package joins the hash-locked supply chain.
  - Early in a month, before MPOB's first price, last month's latest prices are used.
- **Checks.** Anything unexpected rejects the whole document, rather than publishing a misread price:
  - the title, the month, and the column order: North, South, Central, East Coast, Sabah, Sarawak;
  - every cell must be a price or NT/PH;
  - prices must lie between RM 10 and RM 200.

  A fresh read also raises a warning (and so an alert issue) when:
  - its latest price is more than 6 days old;
  - a price is outside 0.8–1.2 × (CPO × 0.01);
  - MPOB's Sarawak footnote changes.
- **Per-region dates.** On a holiday in some regions only, those regions keep their earlier price and its own date, and the app shows that date.
- **When MPOB can't be read** (K7): the last prices stay up, marked `carried_forward`, with their date and a warning. No estimate takes their place.
- **Retired.** The CPO × 0.01 × 0.93 estimate is gone from the scraper. A snapshot from before the switch keeps its "indicative" label until MPOB's price replaces it.
- **In the app:**
  - each region card says "MPOB, at the mill gate", in the reader's language. Sarawak's adds "Miri and Bintulu", MPOB's footnote;
  - under the prices, a dated link opens MPOB's PDF, with a note that dealers usually pay less than the mill-gate price, for transport and their margin;
  - "Where do these prices come from?" explains the source;
  - "Latest from MPOB" links to the same PDF;
  - the calculator's verdict keeps its thresholds and shows the dealer note.
- **Unchanged:**
  - MPOC's CPO price, for the CPO card and the history;
  - MPOB's monthly OER averages;
  - the rule that a run without a CPO price publishes nothing (K7).

## Payload

```json
"ffb": {
  "date": "2026-10-22",
  "regions": [
    {"region": "South", "date": "2026-10-22", "price_1pct_oer": 48.20,
     "avg_oer_pct": 20.28, "source": "MPOB Daily FFB Reference Price (mill gate)",
     "is_indicative": false},
    {"region": "Sarawak", "...": "...", "note": "Miri & Bintulu"}
  ],
  "unit": "RM per tonne of FFB per 1% OER, at the mill gate",
  "source": "MPOB Daily FFB Reference Price (mill gate)",
  "source_url": "https://price.mpob.gov.my/pdf/daily/ffb/2026-10-23",
  "mpob_last_update": "2026-10-22T12:00:00+08:00",
  "is_indicative": false
}
```

Top-level fields are `formula_status: "OFFICIAL"`, `is_indicative: false`, `indicative_notice: null` and `data_source_version: "0.4-mpob-daily"`. Fields of the estimate are no longer written: `indicative_share_factor`, `cpo_price` in `ffb`, and `indicative_fair_price_per_tonne`. `avg_oer_pct` replaces `indicative_oer_pct`, and the app reads both.

## Consequences

### Positive
- Readers see MPOB's own figures, regional as MPOB's are, and can check each one on MPOB's PDF.
- The Fair Price benchmark is the official one the tool was designed around: Price/mt = MPOB Price_1% × graded OER.
- Choosing a region in the calculator now changes the price, as it should.

### Negative / accepted risk
- **MPOB may move or change the PDF**, as it did BEPI in May 2026. The parser rejects what it doesn't recognise, the last prices stay up with their date, and every failed read raises an alert issue.
- **Reuse terms.** The PDF isn't linked from MPOB's home page, and MPOB's site states no reuse terms (© MPOB). SawitSense credits MPOB and links to the PDF wherever the prices appear. Alton may tell MPOB, or ask first; the PDF lists staff to contact.
- **A run still needs a CPO price to publish (K7).** If MPOC fails, MPOB's new prices wait for the next run with a CPO price.
- **The verdict compares a dealer's price with the mill-gate price.** A dealer's usually sits lower by transport and margin, so a small gap is normal; the app says so beside the result.
