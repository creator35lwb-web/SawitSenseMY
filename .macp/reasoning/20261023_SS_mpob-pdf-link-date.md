# Reasoning: why the PDF could show 22 Oct, and the link fix (K27)

**Agent:** SS (Claude Code) · **Date:** 23 Oct 2026

## Facts
- The live data had `ffb.date` 2026-10-23 and `source_url` `.../ffb/2026-10-23`, scraped at 15:24 MYT.
- At 21:17 MYT, MPOB's server answered both `.../ffb/2026-10-22` and `.../ffb/2026-10-23` with the October summary through 23 Oct.
- MPOB's headers: `Content-Disposition: inline; filename="daily_ffb_102026.pdf"` and `Cache-Control: no-cache, private`. There is no ETag or Last-Modified.
- The data commit from 08:37 MYT (5982d21) had `ffb.date` 2026-10-22 but `source_url` `.../ffb/2026-10-23`. The 15:24 MYT commit had the same `source_url`.

## Inference
One address with two contents in one day, under one file name, is the kind of thing a phone's browser, PDF viewer or downloads folder can serve stale. It can't be confirmed without Alton's phone. MPOB's server wasn't wrong when checked.

## Options
1. **Date the link by the prices** (chosen). The address changes exactly when MPOB adds a day, and the date in the address matches the date shown beside the link. It needs no query string, so readers see MPOB's plain address.
2. **Add a version query string** such as `?v=...`. It is untested on MPOB's server, and it makes MPOB's address look altered.
3. **Tell readers to re-download.** This adds wording for a cause that isn't confirmed.

Option 1 doesn't help if a phone reopens a saved file by name alone. If Alton still sees an older copy, ask how it opened.
