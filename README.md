# Spoil

**Spoil them properly.**

A modern South African gift shop — Flutter mobile app + Django REST API.

## Repository branches

Each MVP phase has its own branch:

| Branch | Phase |
|--------|-------|
| `main` | Documentation baseline |
| `phase/1-scaffold-infra` | Project scaffold, Docker, brand shell |
| `phase/2-auth-users` | Authentication & profiles |
| `phase/3-catalog-discovery` | Product catalogue & browsing |
| `phase/4-customisation-cart` | Personalisation & cart |
| `phase/5-checkout-orders` | Paystack checkout & orders |
| `phase/6-occasion-reminders` | My People & reminders |
| `phase/7-content-popia` | Content pages & POPIA |
| `phase/8-admin-launch` | Admin polish & launch readiness |

Work happens on the current phase branch, then merges to `main` before starting the next phase.

## Quick start

### 1. Environment

```bash
cp .env.example .env
```

### 2. Backend (Docker)

```bash
docker compose up --build
```

In another terminal:

```bash
docker compose exec api python manage.py migrate
docker compose exec api python manage.py createsuperuser
```

API health check: [http://localhost:8000/api/health/](http://localhost:8000/api/health/)

Django Admin: [http://localhost:8000/admin/](http://localhost:8000/admin/)

### 3. Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

For a physical device, pass your machine's LAN IP:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000/api/v1
```

Android emulator uses `10.0.2.2` by default.

## Project structure

```
backend/     Django 5 + DRF API
mobile/      Flutter app (Riverpod + go_router)
docs/        SDLC & brand documentation
```

## Core journey

Discover → Personalise → Purchase → Receive