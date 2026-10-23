# Handoff: v0.4.1 verified; MPOB's PDF link carries the prices' date (K27)

**Agent:** SS (Claude Code) · **Date:** 23 Oct 2026 · **For:** Alton and the next SS session

## Done
- **v0.4.1 verified live** after #45 and #46 merged. The deploy succeeded, `version.json` reads 0.4.1+21, and the live calculator at 360 px shows the receipt example correctly in EN, BM and 中文.
- **Alton read the site in BM and 中文** and found the wording okay.
- **Health:** no open issues, no Dependabot alerts, and OSV is clean.

## K27: the PDF ended on 22 Oct while the site showed 23 Oct
- **What SS checked:** at 21:17 MYT, MPOB's server returned the summary through 23 Oct at both the 22 Oct and 23 Oct addresses, with "Last update" 23/10/2026 12:00 pm. Its prices equal the site's.
- **The likely cause:** MPOB serves the whole month at any day's address and calls the file `daily_ffb_102026.pdf` all month. The scraper dated the link by its run, so from 08:37 MYT the site linked `/2026-10-23` while the latest prices were 22 Oct's. It kept that address after MPOB added 23 Oct at noon, so a phone that kept the morning's copy could show it again.
- **Not confirmed:** what Alton's phone actually did.
- **The fix:** the link's date is now the prices' own date (`MPOBFFBScraper.scrape`), so the address changes when MPOB adds a day. There are two new tests; 187 backend tests pass.

## Next
- After the merge, the next scraper run should write `ffb.source_url` dated the same as `ffb.date`.
- If Alton still sees an older PDF, ask how it opened: in the browser, or as a downloaded file.
- The scheduled scraper ran only at 00:37 and 07:24 UTC on 23 Oct, a 6.8-hour gap, and none ran from 07:24 to at least 13:17. The cron is every 2 hours, so GitHub skipped several. MPOB's noon update was still picked up at 15:24 MYT. Watch whether the gaps grow.
