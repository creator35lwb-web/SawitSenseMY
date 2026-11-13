# Reasoning Log: My Sales, a journal on the phone (D29); soupsieve 4.1

**Agent:** SS (Claude Code) · **Date:** 13 Nov 2026
**Related:** handoff `.macp/handoffs/20261113_SS_sales-journal.md`

## Was "D29 is good idea" a yes?

- Alton called it a good idea and asked two questions about how it would work, not whether to do it.
- SS took that as a yes to the journal, with his questions as its requirements: a format he can be told plainly, and export and import that keep the records private.
- The risk of having read him wrong is small. Nothing reaches readers until he merges #58, and the PR says which choices are his to change.

## The security advisory came first

- The routine OSV check found a high-rated advisory in soupsieve, published that morning. The backlog's first item is to handle such a finding in its own PR.
- **Exposure was checked, not assumed.** Soup Sieve only runs when code calls a CSS selector (`select`, `select_one`). The scrapers use `find` and `find_all`. So nothing a hostile page could send would reach it.
- **Still fixed,** because a lock file with a known vulnerability trains everyone to ignore the alert.
- **4.1, not 4.0 or 4.0.1.** The fix is in 4.0. 4.0.1 followed a day later and 4.1 six days after that, so 4.1 is the settled release. It needs Python 3.11.5; the workflows use 3.11, and CI installed it from the lock.

## The journal: choices

- **One JSON text, with plain names.** `date`, `region`, `tonnes`, `price`. Alton asked what the format is; the answer should be readable by someone who opens the browser's storage. Short keys would save a few bytes of a 5 MB allowance that 10,000 sales would not fill.
- **CSV for the file,** because Alton keeps his records in Excel. The same names are its columns.
- **Import is tolerant, and counts what it leaves out.** A spreadsheet that saves the file again changes it: `23/10/2026` for the date, semicolons, quotes, a byte-order mark. All are read. A row that still doesn't make a sale is skipped and counted in the message, never guessed at.
- **A dealer is a letter, A to F.** D29 said no names. A free-text label would have held names within a week. Chips make that impossible, and `Sale.tryParse` drops anything else on import, so a file edited by hand can't bring a name in either.
- **MPOB's price is kept with the sale.** The app's history holds 60 trading days. Without the price, a sale would lose its comparison after three months.
- **A sale follows MPOB's price while its day is in the history.** A sale entered at 9 am is set against yesterday's price, the only one there is, and the card says which day. After noon it moves to its own day's. It never moves back to an earlier day.
- **Storage that refuses is said aloud.** In a private window the browser may discard everything. The save is read back, and if it didn't hold, the screen says to export before closing.
- **No PIN, no encryption.** A PIN kept in the same storage protects nothing, and a real one needs the reader to remember a secret that can't be reset. That is a product decision, so it is put to Alton.
- **D30 not built.** The journal shows the average OER the reader's prices paid for, which is the journal's own total. Using it in the calculator is D30, and Alton hasn't said yes to that.

## What the preview caught that the tests couldn't

- **Whether the browser really keeps it.** The tests use a stand-in for the phone. Only the preview showed the two keys in `localStorage`, the sale surviving a reload, and a real file saved and picked.
- **The first export looked like a failure and wasn't.** No file appeared. The fault was in SS's test script: downloads were allowed for the browser's default profile, not the one the page ran in. Fixed in the script; the app was right.
- **Four tabs at 360 px.** "Papan Pemuka" wrapped onto two lines in BM. The tests don't measure width.

## What SS could not check

- A real phone. iOS Safari and Android Chrome handle a saved file and a file picker in their own ways. The code uses the standard browser calls, and the handoff asks Alton to try it.
