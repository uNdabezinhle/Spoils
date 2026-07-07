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
    "create-auto-gift-proposals-daily": {
        "task": "apps.reminders.tasks.create_auto_gift_proposals",
        "schedule": crontab(hour=9, minute=0),
    },
    "expire-stale-auto-gift-proposals": {
        "task": "apps.reminders.tasks.expire_stale_auto_gift_proposals",
        "schedule": crontab(hour=10, minute=0),
    },
    "process-subscription-renewals-daily": {
        "task": "apps.subscriptions.tasks.process_subscription_renewals",
        "schedule": crontab(hour=6, minute=0),
    },
    "process-surprise-mode-gifts-daily": {
        "task": "apps.reminders.tasks.process_surprise_mode_gifts",
        "schedule": crontab(hour=7, minute=30),
    },
    "expire-unfunded-group-gifts-daily": {
        "task": "apps.group_gifts.tasks.expire_unfunded_group_gifts",
        "schedule": crontab(hour=5, minute=30),
    },
}