# SchedSolicit

A production-quality cross-platform system for managing and selectively sharing schedules and solicitations.

**SchedSolicit** consists of three major components:
1. **(A) Owner App (Flutter 3.x)**: Full-featured offline-first client for mobile and desktop with Material 3 theming, schema-driven dynamic form engine, on-device OCR, classical ML suggestions, background notifications, and multi-format exports.
2. **(B) Backend (Python FastAPI + SQLAlchemy)**: Secure REST API with strict owner/viewer permission isolation, SQLite (PostgreSQL-ready), Alembic migrations, FTS5 search, EasyOCR fallback, scikit-learn models, and live Server-Sent Events (SSE).
3. **(C) Viewer Portal (Next.js 14 PWA)**: Ultra-fast, lightweight read-only responsive web portal optimized specifically for iPhone Safari, featuring native momentum scrolling, safe-area adaptation, offline caching, and PWA "Add to Home Screen" support.

---

## 1. System Architecture & Tech Stack

```
                        +----------------------------+
                        |  (A) Owner App (Flutter)   |
                        |  - Drift (Local SQLite)    |
                        |  - Riverpod & GoRouter     |
                        |  - On-Device OCR (ML Kit)  |
                        +--------------+-------------+
                                       |
                   Sync & REST API     | (Owner Role: Bearer JWT)
                                       v
                     +----------------------------------+
                     |  (B) Backend (FastAPI + SQLite)  |
                     |  - /api/owner/* (Read/Write)     |
                     |  - /api/view/*  (Read-Only, SSE) |
                     |  - Dynamic Field Stripping       |
                     |  - FTS5 Search & Scikit-Learn ML |
                     +-----------------+----------------+
                                       ^
                   Read-Only + SSE     | (Viewer Role: 128-bit Token)
                                       |
                        +--------------+-------------+
                        |  (C) Viewer Portal (Next.js|
                        |  - React 18, Tailwind CSS  |
                        |  - PWA & iOS Safari Engine |
                        |  - Live SSE Subscriptions  |
                        +----------------------------+
```

### Key Technical Decisions
* **Next.js PWA over Flutter Web for Viewer Portal**: Flutter Web downloads a ~3MB CanvasKit bundle and renders onto an HTML `<canvas>`, which degrades initial load speed, breaks native iOS momentum scrolling, and impairs SEO/accessibility. Next.js delivers semantic DOM, sub-200KB JS, Lighthouse 90+ scores, and flawless iPhone Safari integration.
* **Drift over Sqflite for Owner App**: Drift provides compile-time type-safe queries, reactive stream watchers (`watch()`), out-of-the-box migrations, and WebAssembly support, powering the offline-first sync engine.
* **Server-Side Field Stripping**: When a share link conceals financial amounts, contact details, or private notes, the backend strips those fields before JSON serialization. Hidden fields are never sent across the wire.
* **Classical ML over LLMs**: Explainable, deterministic TF-IDF and Logistic Regression classifiers run locally on the server without API keys or token costs.

---

## 2. Directory Structure

```
schedsolicit/
├── docker-compose.yml              # Multi-container orchestration
├── nginx.conf                      # Reverse proxy & SSE buffering config
├── shared/                         # Cross-platform contract files
│   ├── design_tokens.json          # Green-palette M3 tokens, spacing, typography
│   ├── field_schemas.json          # Declarative schedule & solicitation schemas
│   └── status_definitions.json     # Workflow states, badges, and allowed transitions
├── backend/                        # FastAPI REST API & ML Engine
│   ├── alembic/                    # Database migrations
│   ├── src/
│   │   ├── api/                    # /api/owner and /api/view routes
│   │   ├── core/                   # Security, DB connections, configs
│   │   ├── models/                 # SQLAlchemy 2.0 mapped models
│   │   ├── schemas/                # Pydantic v2 validation models
│   │   ├── services/               # Business logic, OCR, ML, FTS5 search
│   │   └── utils/                  # Field stripper, date parsing
│   ├── tests/                      # Pytest suite (auth, search, permissions)
│   ├── scripts/seed_data.py        # 5,000 record stress test generator
│   └── requirements.txt
├── flutter_app/                    # Owner Mobile & Desktop Client
│   ├── lib/
│   │   ├── core/                   # Drift DB, Theme, Router, Sync Engine
│   │   └── features/               # Dynamic form engine, Schedule, Solicitation,
│   │                               # Scan/OCR, Notifications, Export
│   ├── test/                       # Unit, widget, and responsive layout tests
│   └── pubspec.yaml
└── viewer_portal/                  # Next.js 14 Responsive PWA
    ├── src/
    │   ├── app/                    # App Router: [token] views, passcode gate
    │   ├── components/             # Cards, calendar, agenda, responsive layouts
    │   ├── hooks/                  # Live SSE updates, offline caching
    │   └── lib/                    # API client, token adapters
    ├── public/                     # Manifest, Service Worker, icons
    └── package.json
```

---

## 3. Quick Start with Docker

The fastest way to spin up the Backend, Viewer Portal, and Nginx reverse proxy:

```bash
cd schedsolicit
docker-compose up --build
```

* **Viewer Portal & Reverse Proxy**: http://localhost:80
* **Direct Backend OpenAPI Docs**: http://localhost:8000/docs
* **Viewer Direct Dev Server**: http://localhost:3000

---

## 4. Local Development Setup

### Backend (Python 3.11+)
```bash
cd schedsolicit/backend
python -m venv venv
# On Windows:
.\venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
alembic upgrade head
uvicorn src.main:app --reload --port 8000
```

To seed 5,000 realistic records for stress testing:
```bash
python scripts/seed_data.py
```

To execute automated tests:
```bash
pytest tests/ -v
```

### Viewer Portal (Next.js 14)
```bash
cd schedsolicit/viewer_portal
npm install
npm run dev
```

To test PWA production build:
```bash
npm run build
npm start
```

### Owner App (Flutter 3.x)
```bash
cd schedsolicit/flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

To run Flutter tests:
```bash
flutter test
```

---

## 5. iPhone Safari & PWA Testing

1. Connect your iPhone and computer to the same Wi-Fi network.
2. Find your computer's local IP (e.g., `192.168.1.50`).
3. On your iPhone, open **Safari** and navigate to:
   ```
   http://192.168.1.50/
   ```
4. Experience native iOS Safari optimizations:
   - Dynamic viewport sizing with `dvh` units (no jumping address bar).
   - Touch targets strictly formatted to `≥ 44×44 pt`.
   - Native momentum scrolling (`-webkit-overflow-scrolling: touch`).
   - Inputs styled at `16px` font size to completely disable Safari's unwanted auto-zoom.
   - Notch and home indicator adaptation using `env(safe-area-inset-*)`.
5. Tap the **Share** button in Safari and select **"Add to Home Screen"** to test standalone PWA mode.

---

## 6. Security & Permission Enforcements

* **Route Isolation**:
  - `/api/owner/*`: Strict Bearer JWT authentication required. Unauthorized attempts yield `401 Unauthorized`.
  - `/api/view/*`: Accepts 128-bit unguessable tokens with optional Argon2-hashed passcodes. GET operations only; all state mutations are rejected.
* **Server-Side Field Stripping**: When privacy controls (e.g., `hide_amounts: true`) are set on a Share Link, the `FieldStripper` utility actively prunes sensitive keys from dictionaries before the JSON payload is dispatched.
* **Anti-Brute Force**: Passcode rate limiting locks out attempts after 10 failures for 15 minutes.
* **SEO Exclusions**: Private share URLs automatically include `<meta name="robots" content="noindex, nofollow">` to protect unlisted owner information.

---

## 7. License
Licensed under the MIT License.
