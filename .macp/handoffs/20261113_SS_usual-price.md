# Handoff: v0.7.0 verified live; v0.8.0 in review — an offer against the reader's own usual (D30)

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026 · **For:** Alton and the next SS session

## Asked
"Activate SS, PR #58 is merged done." Alton also said yes to D30 and D32, with D32 to wait until the current version is stable and working well for others, and asked SS to check for recent feedback.

## Done
- **v0.7.0 verified live** after #57 and #58 merged.
  - My Sales on the live site at 360 px: add, reload, export, import. All worked.
  - The page made 30 requests, all GET, all to the site itself.
  - A manual scraper run installed soupsieve 4.1 from the lock and finished clean.
- **Feedback checked,** read-only, as Alton asked. Two responses in all, of 16 Oct and 23 Oct; both were acted on (D18, D23). Nothing since.
- **D30 built, in #59 (v0.8.0).** In the calculator, when My Sales holds at least three sales that can be compared:
  - "From My Sales: your last N sales paid for X% OER on average."
  - "This offer is RM Y a tonne above (or below) your usual, at this price per 1% OER."
  - It uses the newest ten sales, averaged by weight; with a region chosen, only sales in that region.
- **Tests:** 16 new in `frontend/test/usual_test.dart`. CI: backend 227, frontend 206.
- **Seen in the preview build at 360 px** in EN, BM and 中文.

## Not done
- **D32 is not started,** as Alton asked. It waits until readers other than Alton are using the app.
- The live site runs v0.7.0 until #59 merges.
- My Sales has still not been tried on a real phone.

## For Alton
1. **Merge #59** after reading the three new lines in BM and 中文 (the `calc_usual` keys).
2. **Try My Sales on your phone:** add a sale, Export, then Import the file. Tell SS what happens, above all on Export and Import.
3. **Still yours to decide:** D28 (SS recommends keeping the 5% band), and the three choices in #58: a dealer as a letter, "Utama" for the first BM tab, no PIN on the journal.
4. **No feedback has come in since 23 Oct.** D32 depends on other growers using the app. If you share the link with a few, their responses are what would tell us the version is working for others.

## Next
- After the merge: the check listed at the top of `PROJECT_STATUS.md`.
