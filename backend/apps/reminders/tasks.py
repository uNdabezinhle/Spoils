import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task
def send_due_reminders():
    from .models import Occasion, ReminderLog

    today = timezone.localdate()
    sent_count = 0

    for occasion in Occasion.objects.filter(is_active=True).select_related("recipient", "recipient__user"):
        reminder_date = occasion.date - timedelta(days=occasion.reminder_days_before)
        if reminder_date != today:
            continue
        already_sent = ReminderLog.objects.filter(
            occasion=occasion,
            sent_at__date=today,
        ).exists()
        if already_sent:
            continue
        ReminderLog.objects.create(occasion=occasion, status="sent")
        logger.info(
            "Reminder sent for %s (%s) — user %s",
            occasion.recipient.name,
            occasion.type,
            occasion.recipient.user.email,
        )
        sent_count += 1

    return {"sent": sent_count}