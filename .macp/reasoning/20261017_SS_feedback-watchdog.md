# Reasoning Log: feedback form watchdog, 2026-10-17

**Agent:** SS (Claude Code) · **Session type:** monitoring
**Related:** handoff `.macp/handoffs/20261017_SS_feedback-watchdog.md`, PR #30

## Decision 1: What can actually break

**The app's side is pinned by tests** (`feedback_test.dart`). The form's side can change without anyone noticing:

- A question recreated in the form gets a new field ID. The prefill then silently does nothing.
- An option reworded in the form means it opens with nothing selected.
- "Accepting responses" turned off means feedback is lost.
- Settings that force a Google sign-in mean readers drop off.

## Decision 2: Check the form, don't submit to it

- **Chosen:** read the public form's own structure (`FB_PUBLIC_LOAD_DATA_`, the data Google embeds in the page) and compare it with the app.
- **Rejected:** a scheduled test submission. Every run would put a fake row in Alton's sheet. It also proves little: Google accepts any response to an open form, so the real risk is the mismatch, not the submit.

## Decision 3: One source of truth

The watchdog reads the URL, field IDs and options from `links.dart` and `feedback_link.dart`. If the app is changed to match a new form, the watchdog follows with no edit.

## Decision 4: Privacy

- The response was read through the Drive connector, read-only.
- Only a summary goes into the repo: date, rating, topic, and that the app details were filled. The free text is paraphrased into D18.
- The sheet's ID is not recorded.

## Mistakes caught mid-session

| Thought | Caught when | Corrected to | Lesson |
|---------|-------------|--------------|--------|
| Use the old scratchpad venv for flake8 | It had been cleaned up | A fresh venv in this session's scratchpad | Same lesson as 9 Oct: don't rely on old temporary folders. |
