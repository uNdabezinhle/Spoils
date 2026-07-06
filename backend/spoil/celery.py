import os

from celery import Celery
from celery.schedules import crontab

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "spoil.settings")

app = Celery("spoil")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()

app.conf.beat_schedule = {
    "send-occasion-reminders-daily": {
        "task": "apps.reminders.tasks.send_due_reminders",
        "schedule": crontab(hour=8, minute=0),
    },
}