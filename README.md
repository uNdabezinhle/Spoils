# Spoil

**Spoil them properly.**

South Africa's modern gift shop — Flutter mobile app + Django REST API.

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
| API base | http://localhost:8000/api/v1/ |

### 3. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

Android emulator uses `http://10.0.2.2:8000/api/v1` by default. For a physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/v1
```

### 4. Smoke tests

Verify the API before launch:

```bash
cd backend
python manage.py test spoil.tests.test_api_smoke
# or
python manage.py smoke_check
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
5. **My People** — Add birthdays/anniversaries with POPIA consent
6. **Profile** — How it works, Privacy & Terms, export/delete data (POPIA)

## Django Admin

Sign in at `/admin/` with your superuser. Key workflows:

- **Orders** — Filter by status; use bulk actions: Processing → Shipped → Delivered
- **Products** — Toggle featured/popular/active inline; manage categories and wrapping
- **Content** — Edit FAQs and static pages (Privacy, Terms, How it Works)
- **Reminders** — View recipients, occasions, and reminder send logs
- **Users** — Profiles, addresses, device tokens

Admin branding: **Spoil Admin** — *Spoil them properly — gift operations*.

## Project structure

```
Spoil/
├── backend/          Django 5 + DRF (users, products, orders, reminders, content)
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
| `EMAIL_HOST` | SMTP; console backend when unset |

## Branch workflow

Each phase was developed on `phase/N-*` and merged to `main`. For new work, branch from `main`.

## Core journey

Discover → Personalise → Purchase → Receive