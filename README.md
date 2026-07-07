# Spoils

**Spoil them properly.**

South Africa's modern gift shop — Flutter mobile app + Django REST API.

**Repository:** https://github.com/uNdabezinhle/Spoils

## MVP status

All eight MVP phases are implemented on `main`:

| Phase | Module |
|-------|--------|
| 1 | Scaffold, Docker, brand shell |
| 2 | Auth, profiles, addresses |
| 3 | Catalog & discovery |
| 4 | Personalisation & cart |
| 5 | Paystack checkout & orders |
| 6 | My People & occasion reminders |
| 7 | Content pages & POPIA |
| 8 | Admin polish & launch readiness |

## Post-MVP features

| Feature | Backend | Mobile |
|---------|---------|--------|
| Occasion detail & gift suggestions | ✅ | ✅ |
| Snooze / skip reminders | ✅ | ✅ |
| People calendar | ✅ | ✅ |
| Subscriptions (Paystack billing + renewals) | ✅ | ✅ |
| Occasion Auto-Gift approval flow | ✅ | ✅ |
| Order status push notifications | ✅ | ✅ (needs Firebase) |
| Staff analytics API + admin dashboard | ✅ | — (admin web) |
| Social login (Google / Apple) | ✅ | ✅ (needs OAuth IDs) |
| Profile photo upload | ✅ | ✅ |
| Loyalty points (earn & redeem) | ✅ | ✅ |
| Group gift / split payments | ✅ | ✅ |
| Live chat support | ✅ | ✅ |
| AR product preview | ✅ | ✅ |
| Phone contacts & calendar import | ✅ | ✅ |
| Surprise mode (autonomous gifting) | ✅ | ✅ |
| Shared family calendars | ✅ | ✅ |
| Anonymous gifting via reminders | ✅ | ✅ |

## Phase-2 polish

| Feature | Backend | Mobile |
|---------|---------|--------|
| Auto-send-once (annual auto-gift) | ✅ | ✅ |
| Mark occasion as sent | ✅ | ✅ |
| Gift suggestion “why we picked this” | ✅ | ✅ |
| Leave family group | ✅ | ✅ |
| Group gift cancel & refunds | ✅ | ✅ |
| Subscription box fulfillment on renewal | ✅ | — (order + push) |
| Live chat incremental polling | ✅ | ✅ |

## Quick start

### 1. Environment

```bash
cp .env.example .env
```

Leave `PAYSTACK_SECRET_KEY` empty for **demo payment mode** (no real charges). Add test keys when ready for Paystack sandbox.

### 2. Backend (Docker)

```bash
docker compose up --build
```

In another terminal:

```bash
docker compose exec api python manage.py migrate
docker compose exec api python manage.py seed_spoil
docker compose exec api python manage.py createsuperuser
```

| Service | URL |
|---------|-----|
| API health | http://localhost:8000/api/health/ |
| Django Admin | http://localhost:8000/admin/ |
| Analytics dashboard | http://localhost:8000/admin/analytics/ |
| API base | http://localhost:8000/api/v1/ |

### 3. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

Android emulator uses `http://10.0.2.2:8000/api/v1` by default. For Chrome or a physical device:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/v1
```

### 4. Tests

**API smoke tests (30):**

```bash
cd backend
python manage.py test spoil.tests.test_api_smoke
```

**Mobile widget tests:**

```bash
cd mobile
flutter test test/post_mvp_screens_test.dart
```

**Device integration tests** (Android emulator or Windows + Visual Studio Build Tools):

```bash
flutter test integration_test/post_mvp_flows_test.dart -d <device> \
  --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

Inside Docker:

```bash
docker compose exec api python manage.py smoke_check
```

## End-to-end journey

1. **Browse** — Home → Shop → product detail
2. **Personalise** — Add message, photo, wrapping → add to cart
3. **Checkout** — Address, delivery date, promo `SPOIL10` → pay (demo or Paystack)
4. **Track** — Orders tab → status stepper, receipt, reorder
5. **My People** — Add birthdays/anniversaries with POPIA consent; import contacts/calendar; family shared calendar; surprise mode & anonymous gifting
6. **Subscriptions** — Profile → monthly spoil plans
7. **Profile** — How it works, Privacy & Terms, export/delete data (POPIA)

## Django Admin

Sign in at `/admin/` with your superuser. Key workflows:

- **Analytics** — Live overview at `/admin/analytics/` (revenue, orders, people, subscriptions)
- **Orders** — Filter by status; bulk actions: Processing → Shipped → Delivered
- **Products** — Toggle featured/popular/active inline; manage categories and wrapping
- **Content** — Edit FAQs and static pages (Privacy, Terms, How it Works)
- **Reminders** — View recipients, occasions, and reminder send logs
- **Subscriptions** — Plans and subscriber management
- **Users** — Profiles, addresses, device tokens

Admin branding: **Spoils Admin** — *Spoil them properly — gift operations*.

## Project structure

```
Spoils/
├── backend/          Django 5 + DRF (users, products, orders, reminders, subscriptions, content)
├── mobile/           Flutter + Riverpod + go_router
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
├── .env.production.example
└── docs/             SDLC & brand documentation
```

## Production deployment

### 1. Configure environment

```bash
cp .env.production.example .env
# Edit .env — secret key, hosts, Paystack live keys, SMTP, Firebase path, CORS origins
```

See `.env.production.example` for every variable. Minimum for go-live:

| Service | Variable(s) |
|---------|-------------|
| Django | `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`, `DJANGO_ALLOWED_HOSTS` |
| Payments | `PAYSTACK_SECRET_KEY`, `PAYSTACK_PUBLIC_KEY` (live keys) |
| Email | `EMAIL_HOST`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` |
| Background jobs | `REDIS_URL` + Celery worker + beat (included in prod compose) |
| Push | `FIREBASE_CREDENTIALS_PATH` → mount JSON in `docker-compose.prod.yml` |
| Photos | `CLOUDINARY_*` or persistent `media_data` volume |
| Social login | `GOOGLE_OAUTH_CLIENT_ID`, `APPLE_CLIENT_ID` |

Register Paystack webhook: `https://<your-api>/api/v1/orders/paystack/webhook/`

### 2. Start production stack

```bash
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml exec api python manage.py migrate
docker compose -f docker-compose.prod.yml exec api python manage.py seed_spoil
docker compose -f docker-compose.prod.yml exec api python manage.py createsuperuser
docker compose -f docker-compose.prod.yml exec api python manage.py production_check --strict
```

Put **nginx** or a cloud load balancer in front of `api:8000` with TLS. Set `DJANGO_BEHIND_PROXY=true` and `DJANGO_CSRF_TRUSTED_ORIGINS=https://your-api-host`.

### 3. Mobile production build

```bash
cd mobile
# Linux/macOS
export API_BASE_URL=https://api.spoils.co.za/api/v1
export FIREBASE_PROJECT_ID=...
export GOOGLE_CLIENT_ID=...   # same as GOOGLE_OAUTH_CLIENT_ID
./scripts/build_production.sh

# Windows PowerShell
$env:API_BASE_URL = "https://api.spoils.co.za/api/v1"
.\scripts\build_production.ps1
```

Configure Firebase in the [Firebase Console](https://console.firebase.google.com/) for Android/iOS, then pass the web app config values as `--dart-define` (see `.env.production.example` comments).

## Environment reference

| Variable | Purpose |
|----------|---------|
| `DJANGO_SECRET_KEY` | Django secret (change in production) |
| `DJANGO_DEBUG` | Must be `false` in production |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated API hostnames |
| `DJANGO_BEHIND_PROXY` | `true` behind nginx/ALB (honours `X-Forwarded-Proto`) |
| `DJANGO_CSRF_TRUSTED_ORIGINS` | HTTPS origins for admin/forms |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Celery broker (reminder emails, renewals) |
| `PAYSTACK_SECRET_KEY` | Empty = demo checkout; `sk_live_*` for production |
| `CLOUDINARY_*` | Photo uploads; falls back to local `media/` volume |
| `FIREBASE_CREDENTIALS_PATH` | FCM push via Firebase Admin SDK JSON |
| `GOOGLE_OAUTH_CLIENT_ID` / `APPLE_CLIENT_ID` | Social login (backend + mobile `GOOGLE_CLIENT_ID`) |
| `EMAIL_HOST` | SMTP; console backend when unset |
| `CORS_ALLOWED_ORIGINS` | Lock down to your app origin(s) in production |

## Branch workflow

Each phase was developed on `phase/N-*` and merged to `main`. For new work, branch from `main`.

## Core journey

Discover → Personalise → Purchase → Receive → Remember → Subscribe