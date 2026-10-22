# Reasoning Log: naming MPOC's bot check, 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** maintenance (follow-up to K22)
**Related:** handoff `.macp/handoffs/20261023_SS_mpoc-bot-check-hint.md`, PR #43, K22, #33

## Why now

- MPOC's price page is the only source a run can't publish without (K7).
- Its own bot check answered SS's machine on 23 Oct. If the same page reaches GitHub's runners, the alert issue should say what happened.
- Today it would say only "0 tables", which reads like a layout change.

## Choices

- **Match a phrase of MPOC's page:** "request is being verified", lower-cased, the same way as the existing hints. Not the title "One moment, please", which is too generic.
- **Name each kind once.** Two signs of a bot check (for example a captcha word as well) still give "looks like a bot check" once.
- **Never repeat the page's text** in the log, as before (the K16 and K22 rule).
- **Don't work around the check.** Genesis v1.1 rules out getting past a bot check. The fix is to report it clearly, so Alton can decide what to do with MPOC (for example, ask them).
