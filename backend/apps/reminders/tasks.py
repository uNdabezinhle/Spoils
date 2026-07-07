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

    from .utils import next_occurrence_on

    for occasion in Occasion.objects.filter(is_active=True).select_related("recipient", "recipient__user"):
        if occasion.snoozed_until and today <= occasion.snoozed_until:
            continue

        next_date = next_occurrence_on(occasion.date, today=today)
        if ReminderLog.objects.filter(occasion=occasion, status="skipped", skip_year=next_date.year).exists():
            continue

        reminder_date = next_date - timedelta(days=occasion.reminder_days_before)
        if reminder_date != today:
            continue
        already_sent = ReminderLog.objects.filter(
            occasion=occasion,
            sent_at__date=today,
        ).exists()
        if already_sent:
            continue

        user = occasion.recipient.user
        days_until = (next_date - today).days
        occasion_label = occasion.get_type_display()

        send_reminder_email(
            user=user,
            recipient_name=occasion.recipient.name,
            occasion_type=occasion_label,
            occasion_date=next_date,
            days_until=days_until,
        )
        send_push_notification(
            user=user,
            title=f"Spoils reminder: {occasion.recipient.name}",
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


@shared_task
def create_auto_gift_proposals():
    from apps.subscriptions.models import UserSubscription

    from .models import Occasion
    from .services.auto_gift import create_proposal_for_occasion

    active_subs = UserSubscription.objects.filter(
        status="active",
        plan__model_type="occasion_auto",
    ).select_related("user", "plan", "occasion")
    created = 0

    for sub in active_subs:
        occasions = Occasion.objects.filter(
            recipient__user=sub.user,
            is_active=True,
        ).select_related("recipient")
        if sub.occasion_id:
            occasions = occasions.filter(pk=sub.occasion_id)
        elif sub.recipient_name:
            occasions = occasions.filter(recipient__name__iexact=sub.recipient_name)

        for occasion in occasions:
            proposal = create_proposal_for_occasion(occasion=occasion, subscription=sub)
            if proposal:
                created += 1
                logger.info(
                    "Auto-gift proposal %s for %s (%s)",
                    proposal.id,
                    occasion.recipient.name,
                    sub.user.email,
                )

    return {"created": created}


@shared_task
def expire_stale_auto_gift_proposals():
    from .models import AutoGiftProposal

    expired = AutoGiftProposal.objects.filter(
        status="pending_approval",
        expires_at__lt=timezone.now(),
    ).update(status="expired")
    return {"expired": expired}


@shared_task
def process_surprise_mode_gifts():
    from .models import Occasion
    from .services.surprise_mode import process_surprise_for_occasion

    processed = 0
    occasions = Occasion.objects.filter(
        is_active=True,
        surprise_mode_enabled=True,
    ).select_related("recipient", "recipient__user")
    for occasion in occasions:
        result = process_surprise_for_occasion(occasion=occasion)
        if result:
            processed += 1
            logger.info(
                "Surprise gift order %s for %s",
                result.get("order_id"),
                occasion.recipient.name,
            )
    return {"processed": processed}