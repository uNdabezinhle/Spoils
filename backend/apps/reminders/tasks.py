import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

from .services.notifications import send_push_notification, send_reminder_email

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

        user = occasion.recipient.user
        days_until = (occasion.date - today).days
        occasion_label = occasion.get_type_display()

        send_reminder_email(
            user=user,
            recipient_name=occasion.recipient.name,
            occasion_type=occasion_label,
            occasion_date=occasion.date,
            days_until=days_until,
        )
        send_push_notification(
            user=user,
            title=f"Spoil reminder: {occasion.recipient.name}",
            body=f"Their {occasion_label.lower()} is in {days_until} days — time to find the perfect gift.",
        )

        ReminderLog.objects.create(occasion=occasion, status="sent")
        logger.info(
            "Reminder sent for %s (%s) — user %s",
            occasion.recipient.name,
            occasion.type,
            user.email,
        )
        sent_count += 1

    return {"sent": sent_count}