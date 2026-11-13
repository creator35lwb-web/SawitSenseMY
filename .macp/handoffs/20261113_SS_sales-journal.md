# Handoff: v0.7.0 in review — My Sales, a journal on the phone (D29); soupsieve 4.1

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026 · **For:** Alton and the next SS session

## Asked
"Activate SS, PR #56 is merged. D29 is good idea ... but what is the format save on browser? the history can be export or import that kept privacy as well?"

## Alton's two questions, answered
1. **The format in the browser.** One JSON text under the key `sawitsense.journal`, in that browser's storage on that phone:
   `{"v":1,"sales":[{"date":"2026-10-23","region":"North","tonnes":5,"price":790,"transport":25,"oer":18.25,"label":"A","mpob_price":47.87,"mpob_date":"2026-10-23"}]}`
   - It is not encrypted: anyone holding the unlocked phone can open the tab, as with a notes app.
   - Clearing the browser's data removes it, and it doesn't follow the reader to another phone.
2. **Export and import, privately.** Yes.
   - Export saves a CSV file with the same names as its columns. It opens in Excel or Google Sheets.
   - Import reads such a file back, on the phone, and adds only the sales that aren't there already.
   - The file goes wherever the reader saves it. The app has no server, and the journal code makes no network request.

## Done
- **#57, security:** soupsieve 2.10 → 4.1 for GHSA-mmhr-3c5m-f64f, published the same day. The scraper never used the affected feature. CI passes.
- **#58, v0.7.0, My Sales (D29):** a fourth tab, in EN, BM and 中文.
  - A sale: date, region, weight, price, transport taken off, the OER on the receipt, a letter for the dealer.
  - Each sale is set against MPOB's price for its region and day; a weekend sale against the last trading day's.
  - Totals for the journal and for each month; delete one sale or all, each after a yes.
  - Export and Import as CSV.
- **Tests:** 51 new in `frontend/test/journal_test.dart`. CI: backend 227, frontend 190.
- **Used end to end in the preview build at 360 px:** add, reload, export, import, in a real browser. The page made GET requests only.
- **Docs:** the README has a section "Your sales journal" with the format; `AGENTS.md` lists what browser storage may hold and the rules for the journal; `CHANGELOG.md` has 0.7.0.

## Not done
- The live site still runs v0.6.0 until #58 merges.
- Not tried on a real iPhone or Android phone, only in desktop Chrome emulating one. Saving and picking a file are the parts most likely to differ there.
- D30 is not built: the calculator doesn't use the journal yet.

## For Alton
1. **Merge #57, then #58,** or #58 alone: it carries #57's commit.
2. **Try it on your own phone after the merge,** above all Export and Import, and tell SS what happens.
3. **Three choices SS made that are yours to change:**
   - a dealer is a letter, A to F, picked from chips. No name can be typed;
   - the first tab in BM reads "Utama" instead of "Papan Pemuka", which no longer fits with four tabs;
   - the journal isn't locked with a PIN or encrypted. A PIN would be a new decision.
4. **Still waiting for your yes:** D30, D32 (SS recommends not yet), D28 (keep the 5% band).

## Next
- After the merges: the checks listed at the top of `PROJECT_STATUS.md`.
