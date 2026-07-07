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

**API smoke tests (22):**

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
5. **My People** — Add birthdays/anniversaries with POPIA consent; calendar & occasion detail
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
├── .env.example
└── docs/             SDLC & brand documentation
```

## Environment reference

| Variable | Purpose |
|----------|---------|
| `DJANGO_SECRET_KEY` | Django secret (change in production) |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Celery broker (reminder emails) |
| `PAYSTACK_SECRET_KEY` | Empty = demo checkout; set for Paystack |
| `CLOUDINARY_*` | Photo uploads; falls back to local `media/` in DEBUG |
| `FIREBASE_CREDENTIALS_PATH` | FCM push (optional; logs stub when empty) |
| `GOOGLE_OAUTH_CLIENT_ID` / `APPLE_CLIENT_ID` | Social login (optional) |
| `EMAIL_HOST` | SMTP; console backend when unset |

## Branch workflow

Each phase was developed on `phase/N-*` and merged to `main`. For new work, branch from `main`.

## Core journey

Discover → Personalise → Purchase → Receive → Remember → Subscribe