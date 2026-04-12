# AGENTS.md — SawitSenseMY

## Session Protocol

1. **Start:** Read this file, then README.md, then `.macp/handoffs.json` for latest state
2. **Work:** Implement changes per current phase
3. **Test:** Run `pytest backend/tests/` for backend changes
4. **End:** Create handoff record in `.macp/handoffs.json`

## Lint / Test Commands

```bash
# Backend
cd backend && pip install -r requirements.txt
pytest tests/ -v
python -m flake8 scrapers/ writer/ monitor/ --max-line-length=120

# Frontend (Phase 2)
cd lib && flutter analyze
flutter test
```

## Key Files

- `backend/scrapers/mpob_bepi.py` — Core MPOB scraper
- `backend/writer/firestore_writer.py` — Firestore + JSON writer
- `backend/monitor/health_check.py` — Scraper health monitoring
- `backend/run_scraper.py` — Pipeline orchestrator
- `.github/workflows/scraper_cron.yml` — Automated 2x daily scrape

## Core Formula

```
Price/mt = MPOB_Price_1% x Graded_OER%
```

Do NOT use: `CPO x 0.25 x 0.796` (rejected — unverifiable constants)

## Architecture Decisions

- Prototype-first: public read-only dashboard, zero auth
- Offline-first: always cache last known prices
- Local-first: Sales Journal data stored locally by default
- Module 5 (Dealer Map): deferred to last phase with anti-manipulation safeguards
