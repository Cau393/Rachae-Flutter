<div align="center">
  <img src="frontend/assets/branding/logo.png" alt="Rachae" width="100" />

  <h1>Rachae</h1>

  <p><em>from the Brazilian Portuguese <strong>rachar</strong> — to split</em></p>

  <p>A free, open-source expense-splitting app. Because splitting bills shouldn't cost money.</p>

  <p>
    <a href="https://github.com/Cau393/Rachae-Flutter/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT License" /></a>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter 3" />
    <img src="https://img.shields.io/badge/Django-6.0-092E20?logo=django&logoColor=white" alt="Django 6" />
    <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey" alt="Platforms" />
    <a href="https://github.com/Cau393/Rachae-Flutter/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome" /></a>
  </p>
</div>

---

## Why Rachae?

Splitwise is great — but its free tier is increasingly limited, and the premium plan costs money every month just to track who owes who for pizza.

**Rachae is the alternative.** It's fully open source, completely free to use, and covers everything you'd expect from a modern expense-splitting app: groups, friends, multi-currency, debt simplification, and settlement tracking. You can self-host it in minutes or use the hosted version.

---

## Features

### Expense Splitting
- **Three split modes** — equal, unequal (fixed amounts), or percentage per person
- **Multi-currency groups** — each group has a base currency; expenses can be in any currency and are converted using live exchange rates
- **Smart debt simplification** — the ledger collapses chains of debt so fewer transactions settle everything
- **Receipt uploads** — attach proof to any expense (stored on S3)

### Groups & Friends
- **Groups with roles** — Admin, Editor, and Viewer permissions per member
- **Friend invites via deep link** — share a link; when the recipient signs up, the friendship is automatically accepted
- **Pending approvals queue** — flag expenses for review before they're finalized

### Dashboard & Activity
- Balance summary at a glance — who owes you, who you owe
- Activity feed across all groups and friends
- Pending settlements view

### Settlement Flow
- Record a payment and request the other person to confirm
- Upload proof of transfer (screenshot, receipt)
- Offset-credit previews before you settle

### Platform
- **iOS, Android, and Web** from a single Flutter codebase
- **Internationalized** — English, Portuguese, and Portuguese (Brazil)
- **PDF export** — download your full spending history
- **Ad-supported** (AdMob on mobile, AdSense on web) with an optional ad-free upgrade via in-app purchase (RevenueCat) or web subscription (Stripe)

---

## Tech Stack

### Frontend — Flutter

| Concern | Library / Decision |
|---|---|
| Framework | [Flutter](https://flutter.dev) 3 · Dart 3.11 |
| State management | [Riverpod](https://riverpod.dev) 3 — `AsyncNotifier` for mutations, `AsyncValue` for UI states |
| Navigation | [go_router](https://pub.dev/packages/go_router) 17 — typed routes, centralized in `lib/core/router/` |
| HTTP | [Dio](https://pub.dev/packages/dio) 5 — shared client with auth interceptor; never instantiated per-call |
| Auth | [supabase_flutter](https://pub.dev/packages/supabase_flutter) 2 — OAuth + JWT; tokens stored in `flutter_secure_storage` |
| In-App Purchases | [purchases_flutter](https://pub.dev/packages/purchases_flutter) (RevenueCat) |
| Ads | [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) + App Tracking Transparency |
| Deep linking | [app_links](https://pub.dev/packages/app_links) — invite tokens + OAuth callbacks |
| PDF export | [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) |
| Localization | `flutter_localizations` + `intl` — ARB-driven, generated; never hardcode strings |
| Images | [cached_network_image](https://pub.dev/packages/cached_network_image) |

### Backend — Django + DRF

| Concern | Library / Decision |
|---|---|
| Framework | [Django](https://djangoproject.com) 6 + [Django REST Framework](https://www.django-rest-framework.org) 3.16 |
| Authentication | Supabase JWT verified against JWKS — zero shared-secret dependency; supports ES256 + RS256 |
| Async tasks | [Celery](https://docs.celeryq.dev) 5 + [django-celery-beat](https://django-celery-beat.readthedocs.io) — emails, notifications, ledger cache, webhooks |
| Message broker | Redis (Upstash for hosted) |
| Database | PostgreSQL (production) · SQLite (tests only) |
| Static files | [WhiteNoise](https://whitenoise.readthedocs.io) — serves from Gunicorn, no extra CDN needed for static assets |
| File storage | AWS S3 via [boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html) — receipts, export files, settlement proofs |
| Push notifications | Firebase Admin SDK (FCM) |
| Email | [Brevo](https://www.brevo.com) transactional templates |
| Payments | [Stripe](https://stripe.com) (web subscriptions) + [RevenueCat](https://www.revenuecat.com) webhook sync |
| Error tracking | [Sentry](https://sentry.io) |
| Process manager | Gunicorn (production) · Uvicorn (development) |

### Infrastructure

| Service | Purpose |
|---|---|
| Vercel | Flutter web (static build) |
| Railway | Django API (web + worker + beat) |
| AWS RDS | PostgreSQL — `sa-east-1` |
| AWS S3 | File storage — `sa-east-1` |
| Upstash | Serverless Redis |
| Supabase | Auth (OAuth, JWKS, user management) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Client                         │
│                                                         │
│  features/<name>/                                       │
│    models · providers (Riverpod) · repositories · ui   │
│                                                         │
│  core/                                                  │
│    network (dio + interceptor) · router · theme         │
│    revenuecat · currency · shared widgets               │
└───────────┬─────────────────────────┬───────────────────┘
            │ HTTPS + Bearer JWT       │ Supabase Realtime
            ▼                          ▼
┌───────────────────────┐   ┌──────────────────────────┐
│   Django REST API     │   │        Supabase           │
│                       │   │                          │
│  apps/<domain>/       │   │  Auth (OAuth, email/pw)  │
│    models · queries   │   │  JWKS endpoint           │
│    services · views   │   │  User management         │
│                       │   └──────────────────────────┘
│  core/                │
│    SupabaseJWTAuth    │◄── verifies every request
│    (JWKS, ES256/RS256)│    against public keys
│                       │
│  Celery workers       │──► Redis broker
│    emails · S3 tasks  │       │
│    ledger cache       │   ┌───┴──────────────────────┐
│    stripe · FCM       │   │     Background Tasks     │
└───────────┬───────────┘   │  beat · worker · broker  │
            │               └──────────────────────────┘
            ▼
┌───────────────────────┐
│   PostgreSQL (RDS)    │
│   AWS S3 (files)      │
└───────────────────────┘
```

### Key Design Decisions

**Dual identity model** — Every user has both a Supabase UID (auth layer) and a Django database ID (application layer). The backend reconciles them on first request via JWT claims, keeping auth fully decoupled from business logic.

**JWKS token verification** — The backend fetches Supabase's public signing keys and verifies every JWT locally. No shared secret, no auth round-trips per request.

**Redis-cached balance ledger** — Group balances are computed from the full transaction graph and cached in Redis. The cache is invalidated on write via Celery tasks, keeping reads fast without stale data.

**Feature-first structure** — Both frontend and backend are organized by domain (`features/<name>/` on Flutter, `apps/<name>/` on Django), not by layer. Each domain owns its models, business logic, and API surface.

**Thin views, fat services** — DRF views are lean REST wrappers. All business logic lives in `services.py` and `queries.py`. Views never touch the database directly.

**Platform-conditional stubs** — Web and native diverge on file storage, deep linking, and ads. Each split uses a shared `_stub.dart` interface with `_web.dart` / `_io.dart` implementations, keeping the shared layer clean.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.11
- Python ≥ 3.10 (3.13 recommended) + [uv](https://github.com/astral-sh/uv) or pip
- PostgreSQL or Docker (for local DB)
- Redis (local or [Upstash](https://upstash.com) free tier)
- A [Supabase](https://supabase.com) project (free tier is fine)

---

### Backend

```bash
cd backend

# Create and activate a virtual environment
python -m venv .venv && source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy and fill in the environment file
cp ../.env.example .env   # edit with your Supabase URL, DB URL, Redis URL

# Apply migrations and start the dev server
python manage.py migrate
make asgi              # → http://localhost:8000
```

> Settings read `.env` from the **repo root** (`ROOT_DIR/.env`), so copy the
> template to the root, not into `backend/`. Only `DJANGO_SECRET_KEY`,
> `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`, `CORS_ALLOWED_ORIGINS`,
> `CORS_ALLOWED_ORIGIN_REGEXES`, and `DATABASE_URL` are required to boot; the
> rest are optional integrations.

> **Firebase push notifications are optional.** `FIREBASE_CREDENTIALS_JSON` is a
> **file path** to a service-account JSON (not the JSON contents). Leave it
> **unset** to run without FCM — it degrades gracefully. If you set it, the file
> **must exist** or `manage.py` (including `collectstatic`) crashes at startup
> with `ImproperlyConfigured: Firebase credentials file not found`. The
> credential file and `.secrets/` are gitignored, so they are never present in a
> fresh clone.

The dev server runs with Uvicorn (ASGI). The API is available at `http://localhost:8000/api/v1/`. Health check: `GET /api/v1/health/`.

**Run tests:**
```bash
DJANGO_SETTINGS_MODULE=config.test_settings python -m pytest
```

Tests use SQLite in-memory and eager Celery tasks — no external services required.

**Start the Celery worker** (needed for async tasks — emails, S3 confirms, ledger cache):
```bash
celery -A config worker --loglevel=info
celery -A config beat --loglevel=info \
  --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

---

### Frontend

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Copy env and fill in Supabase + API keys
cp ../.env.example .env

# Run on any connected device or simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1/

# Run the full test suite
flutter test

# Lint
flutter analyze
dart format lib test
```

**Platform builds:**
```bash
# Web
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.rachae.app/api/v1/

# iOS
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://api.rachae.app/api/v1/ \
  --dart-define=REVENUECAT_IOS_API_KEY=your_key
```

---

## Deployment

The project ships to:

| Component | Platform |
|---|---|
| Flutter web | Vercel (static build) |
| Django API | Railway (web service) |
| Database | AWS RDS PostgreSQL |
| Redis | Upstash |
| Auth | Supabase |
| iOS app | App Store |

A detailed step-by-step deployment runbook (AWS security groups, Supabase redirect config, Railway service setup, Vercel build args, iOS signing) is maintained in the project's [deployment plan](.claude/plans/).

> **Note:** Celery worker and beat are defined in the `Procfile` but are deployed as separate Railway services. The web API runs independently — async tasks are queued but not consumed until the worker is running.

> **Railway/Firebase gotcha:** Do **not** set `FIREBASE_CREDENTIALS_JSON` to a
> file path in Railway variables. The value is read as a filesystem path, but the
> credential file is gitignored and never shipped to the container, so the build
> fails during `collectstatic` with `ImproperlyConfigured: Firebase credentials
> file not found`. Leave the variable unset on Railway (push notifications
> degrade gracefully) until file-based secrets are wired in, e.g. via a Railway
> volume or a build step that materializes the JSON from a base64 variable.

---

## Project Structure

```
Rachae-Flutter/
├── frontend/                   # Flutter application
│   ├── lib/
│   │   ├── features/           # One directory per product domain
│   │   │   ├── auth/
│   │   │   ├── dashboard/
│   │   │   ├── expenses/
│   │   │   ├── groups/
│   │   │   ├── settlements/
│   │   │   ├── friends/
│   │   │   ├── profile/
│   │   │   ├── currencies/
│   │   │   └── ads/
│   │   ├── core/               # Shared infra (network, router, theme)
│   │   └── src/                # App bootstrap, config, platform shims
│   ├── ios/
│   ├── android/
│   └── web/
│
└── backend/                    # Django API
    ├── apps/                   # One Django app per domain
    │   ├── users/
    │   ├── groups/
    │   ├── expenses/
    │   ├── splits/
    │   ├── transactions/
    │   ├── ledger/
    │   ├── currencies/
    │   └── notifications/
    ├── core/                   # Supabase JWT auth, base models, S3
    ├── config/                 # Django settings, Celery, WSGI/ASGI
    └── tasks/                  # Cross-domain Celery tasks
```

---

## Contributing

Contributions are welcome. Please open an issue before submitting a large pull request so we can align on direction.

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Follow the existing conventions (feature-first structure, thin views, localize all strings)
4. Make sure `flutter test`, `flutter analyze`, and the Django test suite all pass
5. Open a PR

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">
  <sub>Built as a free alternative to expense-splitting apps that charge for basic functionality.</sub><br />
  <sub>If Rachae saves you money, consider starring the repo.</sub>
</div>
