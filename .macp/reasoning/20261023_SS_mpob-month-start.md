# Reasoning Log: MPOB's month start, 2026-10-23

**Agent:** SS (Claude Code) · **Session type:** proactive check, fix
**Related:** handoff `.macp/handoffs/20261023_SS_mpob-month-start.md`, PR #44, K26, K23, K7, ADR-002

## Test the boundary now, not on the day

- The month change was listed as "check on 1 November".
- Asking MPOB's server about November and December cost two requests and answered it a week early.
- The answer was a 500, which none of #40's tests had assumed: they covered 404 and an empty table.

## Choices

- **A 500 means "no document" only after every attempt.** A passing 500 is retried first.
- **Fall back to last month only in the first 7 days.** MPOB's first trading day comes within a few days of the 1st. Later in a month, a month without prices is a fault, and an alert is right.
- **Keep K23.** 503, a timeout or a refused connection mean MPOB is down. Last month's PDF is on the same server, so it isn't tried.
- **Never replace newer prices with older ones (K7).**
  - The fallback could otherwise do so: for example, on 3 November a passing 500 for November would bring back October's last prices after November's first price was already shown.
  - The guard sits in `decide_payload`, beside the other K7 rules.
  - It doesn't apply to an estimate from before D22, which any MPOB read replaces.

## Mistakes caught

| Thought | Caught when | Corrected to | Lesson |
|---------|-------------|--------------|--------|
| #40 assumed MPOB answers 404 for a month without prices | Asked MPOB's server about November on 23 Oct: HTTP 500 | Treat a persistent 500 as no document, early in a month only | A source's error codes are part of its behaviour. Ask the server what it does at the edges (a new month, no data, a far date) before assuming a 404. |
| Fall back to last month on any 500 | Thinking through a passing 500 on 3 November | Fall back only in the first 7 days, and add the K7 guard for older reads | Every fallback needs a rule that it never replaces better data. |
