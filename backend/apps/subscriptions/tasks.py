import logging

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)


@shared_task
def process_subscription_renewals():
    from .models import UserSubscription
    from .services.billing import renew_subscription

    today = timezone.localdate()
    due = UserSubscription.objects.filter(status="active", next_billing_date__lte=today).select_related(
        "plan", "user"
    )
    renewed = 0
    failed = 0
    for sub in due:
        if renew_subscription(sub):
            renewed += 1
            logger.info("Renewed subscription %s for %s", sub.id, sub.user.email)
        else:
            failed += 1
            logger.warning("Failed renewal for subscription %s (%s)", sub.id, sub.user.email)
    return {"renewed": renewed, "failed": failed}