"""Validate production environment before go-live."""

from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = "Check production configuration (run with DJANGO_DEBUG=false before deploy)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--strict",
            action="store_true",
            help="Fail on warnings (recommended in CI deploy pipelines).",
        )

    def handle(self, *args, **options):
        strict = options["strict"]
        errors: list[str] = []
        warnings: list[str] = []

        if settings.DEBUG:
            errors.append("DJANGO_DEBUG must be false in production.")

        if settings.SECRET_KEY in ("dev-insecure-change-in-production", "change-me-to-a-secure-random-string", ""):
            errors.append("DJANGO_SECRET_KEY is still the default placeholder.")

        hosts = set(settings.ALLOWED_HOSTS)
        if hosts <= {"localhost", "127.0.0.1", "10.0.2.2"}:
            errors.append("DJANGO_ALLOWED_HOSTS must include your public API hostname.")

        if settings.CORS_ALLOW_ALL_ORIGINS:
            errors.append("CORS_ALLOW_ALL must be false in production.")

        if not settings.CORS_ALLOWED_ORIGINS:
            warnings.append("CORS_ALLOWED_ORIGINS is empty — mobile/web clients may be blocked.")

        if not settings.PAYSTACK_SECRET_KEY:
            warnings.append("PAYSTACK_SECRET_KEY is empty — checkout runs in demo mode.")

        if settings.PAYSTACK_SECRET_KEY.startswith("sk_test"):
            warnings.append("Paystack is in test mode (sk_test_*). Use sk_live_* for production.")

        if not settings.EMAIL_HOST:
            warnings.append("EMAIL_HOST is unset — emails print to console only.")

        if not settings.REDIS_URL or settings.REDIS_URL == "redis://localhost:6379/0":
            warnings.append("REDIS_URL should point to your production Redis (Celery/reminders).")

        if not settings.FIREBASE_CREDENTIALS_PATH:
            warnings.append("FIREBASE_CREDENTIALS_PATH is unset — push notifications will be stubbed.")
        elif not Path(settings.FIREBASE_CREDENTIALS_PATH).is_file():
            errors.append(f"Firebase credentials file not found: {settings.FIREBASE_CREDENTIALS_PATH}")

        if not settings.CLOUDINARY_CLOUD_NAME:
            warnings.append("Cloudinary is unset — uploads use local media/ (ensure persistent volume).")

        if not settings.DEBUG and not settings.CSRF_TRUSTED_ORIGINS:
            warnings.append("DJANGO_CSRF_TRUSTED_ORIGINS is empty — admin/forms behind HTTPS may fail.")

        for msg in warnings:
            self.stdout.write(self.style.WARNING(f"WARN: {msg}"))
        for msg in errors:
            self.stdout.write(self.style.ERROR(f"ERROR: {msg}"))

        if errors or (strict and warnings):
            raise CommandError("Production check failed.")

        self.stdout.write(self.style.SUCCESS("Production check passed — Spoil them properly."))