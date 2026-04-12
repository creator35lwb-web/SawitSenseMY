# SawitSense MY

**Sawit Kita, Harga Kita** | Open-Source CPO Price Tracker & OER Signal

---

## What Is SawitSense?

SawitSense is an open-source, smallholder-first FFB (Fresh Fruit Bunch) price transparency tool for Malaysian oil palm farmers.

It solves a structural **information asymmetry** in the palm oil supply chain: the dealer knows the CPO price and assigns the OER grading — the smallholder usually doesn't see either before being quoted a price.

```
SMALLHOLDER (you)
       | sells FFB at dealer's quoted price
LICENSED DEALER
       | deducts transport, assigns OER, takes margin
PALM OIL MILL
       | processes at CPO market rate
MARKET PRICE (Bursa / MPOB)
```

**SawitSense puts the numbers in the smallholder's hand before they sell.**

---

## The Core Formula (Confirmed)

```
Price/mt = MPOB Price_1% x Graded_OER%
```

- **Price_1%** — MPOB publishes a Daily FFB Reference Price at 1% OER, broken down by 6 regions: North, South, Central, East Coast, Sabah, Sarawak
- **Graded_OER%** — The Oil Extraction Rate your dealer/mill assigns to your FFB (typically 17-22%)
- **Each 1% OER is worth ~RM 42+/tonne** — this is the hidden lever

Example: If the rate is RM 42.77/1% OER and your OER is 18%:
`RM 42.77 x 18 = RM 769.86/tonne`

> **Rejected Formula:** `CPO x 0.2? x 0.7?` — An unofficial shorthand circulating among dealers using unverifiable constants of unknown origin. Permanently excluded from SawitSense to protect data integrity.

---

## Feature Modules

### Phase 1 (Prototype) — Public Dashboard

| Module | Description | Status |
|--------|-------------|--------|
| **M1: Daily Price Dashboard** | Today's MPOB FFB Reference Price by region + CPO spot price | Building |
| **M2: Fair Price Calculator** | Input OER% + Region = benchmark price. Compare vs dealer quote. OER sensitivity slider. | Building |
| **M4: Price History** | 30/90/365-day CPO price chart with trend signal | Building |
| **Feedback Button** | "What else would you like?" — 3 preset options for market signal | Building |

### Phase 2 (Production) — After Market Fit Confirmed

| Module | Description | Status |
|--------|-------------|--------|
| **M3: My Sales Journal** | Log each sale: date, weight, OER%, dealer, price. Local-first, cloud opt-in. | Planned |
| **M5: Dealer Transparency Map** | Anonymous crowdsourced dealer pricing by area. Deferred to last with anti-manipulation safeguards. | Planned |

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|----------|
| Frontend | Flutter Web | Cross-platform, mobile-responsive |
| State Management | Riverpod | Scalable upgrade from Provider |
| Backend/Scraper | Python + GitHub Actions | Zero hosting cost |
| Database | Firestore | Real-time sync, offline capable |
| Charts | fl_chart | Interactive price visualization |
| Auth (Production) | Firebase Auth (Phone OTP) | Smallholders use phone numbers |
| Languages | BM + English + Chinese | Malaysian multicultural reality |
| Hosting | GitHub Pages | Free tier |

---

## Data Pipeline

```
MPOB BEPI (scraper, 2x daily at 8:30am + 4:30pm MYT)
    -> FFB Reference Price (6 regions) + CPO spot price
         |
    GitHub Actions Cron Job (free)
         |
    Firestore + JSON fallback
         |
    Flutter Web App (GitHub Pages)
```

Data freshness indicator: GREEN (<6h) | AMBER (6-12h) | RED (>12h)

---

## Project Structure

```
SawitSenseMY/
+-- backend/              # Python MPOB scraper + caching
|   +-- scrapers/          # MPOB BEPI scraper
|   +-- writer/            # Firestore writer
|   +-- monitor/           # Health check + alerts
|   +-- tests/             # Unit tests
|   +-- run_scraper.py     # Pipeline orchestrator
|   +-- requirements.txt   # Python deps
+-- lib/                   # Flutter app (Phase 2)
+-- docs/                  # Project documentation
+-- .macp/                 # MACP v2.2 protocol files
+-- .github/workflows/     # GitHub Actions
+-- peas/                  # VerifiMind validation reports
+-- AGENTS.md              # Agent instructions
+-- README.md              # This file
```

---

## Risk Register

| # | Risk | Severity | Mitigation | Phase |
|---|------|----------|------------|-------|
| R1 | MPOB scraper fragility | HIGH | Health monitor + Commodities-API fallback + freshness indicator | 1 |
| R2 | Rural connectivity | MEDIUM | Offline-first, cached prices with timestamp | 2 |
| R3 | Digital literacy | MEDIUM | Picture-based tutorial, WhatsApp share button | 2 |
| R4 | Dealer map manipulation | HIGH | Deferred to Phase 2 with: anomaly detection, rate limiting, account age, median not mean | 2 |
| R5 | Sybil attacks | HIGH | Device fingerprinting, 30-day account age, MPOB anchor display | 2 |
| R6 | Smallholder data privacy | MEDIUM | Local-first storage, cloud opt-in, user-scoped Firestore rules | 2 |

---

## Team (MACP v2.2)

| Agent | Role | Platform |
|-------|------|----------|
| **Alton** | Human Orchestrator, Founder, Smallholder (~5 acres) | Human |
| **SS** | CTO, Intelligence Tracker | Claude.ai |
| **QQ** | CSO, Execution Lead | Qoder |

---

## Validation

| Run | Score | Verdict |
|-----|-------|---------|
| Trinity Run 1 (Full Platform) | 8.0/10 | PROCEED |
| Trinity Run 2 (Prototype-First) | 8.4/10 | STRONGLY PROCEED |
| CS Deep-Dive (v1.2 Calculator) | 8.5/10 | PROCEED, 0 vulnerabilities |

---

## Why This Matters

Indonesia and Malaysia together constitute 85% of the world's palm oil supply. In 2024, Malaysia's CPO average price hit RM 4,179.50/tonne, with total export earnings surging to RM 109.39 billion. There are **500,000+ smallholder farmers** who check CPO prices daily — yet there's no clean, open-source, mobile-friendly tool for them.

SawitSense fills that gap.

---

## License

MIT License. See [LICENSE](LICENSE).

**Sawit Kita, Harga Kita.**
