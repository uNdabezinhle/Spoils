"""Quick launch-readiness check — runs the API smoke test suite."""

from django.core.management.base import BaseCommand
from django.core.management import call_command


class Command(BaseCommand):
    help = "Run API smoke tests to verify launch readiness."

    def handle(self, *args, **options):
        self.stdout.write("Running Spoils API smoke tests...")
        call_command("test", "spoil.tests.test_api_smoke", verbosity=1)
        self.stdout.write(self.style.SUCCESS("Smoke tests passed — Spoil them properly."))