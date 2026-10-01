# AGENTS.md — SawitSenseMY

## Active Agent

**SS (Claude Code)**, CTO & Lead Maintainer, is the only active agent and reports to Alton (Founder, Human Orchestrator). See `SS_Claude_Code_Genesis_Master_Prompt_v1.0.md`; the full registry is in `.macp/agents.json`.

## Session Protocol

1. **Start:** Read this file, then `PROJECT_STATUS.md`, then the newest handoff in `.macp/handoffs/`. Check open Issues (`scraper-alert`, `deploy-alert`, `freshness-alert`) and open PRs.
2. **Work:** Branch, diagnose before patching, test.
3. **Land:** Open a pull request. CI must pass. Alton reviews and merges. Agents never push to `main` and never merge. GitHub deletes the PR's branch after the merge (D12), so run `git fetch --prune` and start the next change from a fresh branch off `main`.
4. **End:** Update `PROJECT_STATUS.md`. Write a handoff in `.macp/handoffs/YYYYMMDD_SS_<topic>.md` and a reasoning log in `.macp/reasoning/YYYYMMDD_SS_<topic>.md`.

Handoffs up to 21 May 2026 are archived in `.macp/handoffs.json`.

## Lint / Test Commands

```bash
# Backend
cd backend && pip install -r requirements.txt pytest flake8
pytest tests/ -v
python -m flake8 scrapers/ writer/ monitor/ run_scraper.py --max-line-length=120

# Frontend
cd frontend && flutter pub get
flutter analyze
flutter test
```

On every pull request, CI (`.github/workflows/ci.yml`) runs all of the above plus a credential scan. It also uploads the web build as a `web-preview` artifact, so UI changes can be seen at phone width before merging (see "Previewing UI changes" in `PROJECT_STATUS.md`).

## Key Files

- `backend/run_scraper.py`: pipeline orchestrator (Path C, ADR-001)
- `backend/scrapers/mpoc_cpo.py`: daily CPO price (MPOC)
- `backend/scrapers/mpob_oer.py`: monthly OER by state (MPOB Prestasi Sawit)
- `backend/scrapers/mpob_bepi.py`: core formula plus the legacy MPOB BEPI scraper. This is the math layer; don't refactor it.
- `backend/writer/json_writer.py`: writes the JSON snapshots the app reads
- `backend/monitor/`: scraper health check and live-site freshness watchdog
- `.github/workflows/scraper_cron.yml`: scrapes every 2 hours, every day (D13), then dispatches the deploy
- `.github/workflows/deploy_web.yml`: builds and deploys the Flutter web app
- `.github/workflows/freshness_watchdog.yml`: raises an alert when the live site falls behind `main`

## Languages

Every string a user sees goes in all three tables in `frontend/lib/l10n/`: `app_en.dart`, `app_ms.dart` and `app_zh.dart` (Simplified Chinese). `frontend/test/l10n_test.dart` fails if a key is missing from any of them. A native reader should check new Malay or Chinese wording before it ships.

The app opens in the reader's last choice on that phone, or else the phone's language, or else English (`initialLocale` in `l10n_provider.dart`). The choice is kept in the browser's localStorage as `en`, `ms` or `zh` under `sawitsense.language`. Keep it that small: no personal data goes in browser storage.

## Core Formula

```
Price/mt = MPOB_Price_1% x Graded_OER%
```

Do NOT use: `CPO x 0.2? x 0.7?` (rejected — unverifiable constants from unofficial dealer shorthand)

While MPOB's reference price is unavailable, the indicative `CPO x 0.01 x 0.93` (ADR-001) may be used. It must always be labelled `is_indicative: true`.

## Secrets and Privacy

This public repo is the project's single source of truth, so never commit:

- credentials (they belong in GitHub Actions secrets)
- personal data about smallholders, dealers or mills
- private notes

Only the scraper writes to `backend/data/`.

## Architecture Decisions

- Prototype-first: public read-only dashboard, zero auth
- Offline-first: always cache last known prices (not built yet; see `PROJECT_STATUS.md`)
- Local-first: Sales Journal data stored locally by default
- Module 5 (Dealer Map): deferred to last phase with anti-manipulation safeguards
