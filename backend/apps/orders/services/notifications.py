import logging

from django.conf import settings
from django.core.mail import send_mail

from apps.reminders.services.notifications import send_push_notification

from ..order_serializers import STATUS_LABELS

logger = logging.getLogger(__name__)


def send_order_status_email(*, order) -> None:
    user = order.user
    label = STATUS_LABELS.get(order.status, order.status.replace("_", " ").title())
    subject = f"Spoils order #{order.id} — {label}"
    body = (
        f"Hi {user.first_name or 'there'},\n\n"
        f"Your Spoils order #{order.id} is now: {label}.\n\n"
        f"Open the Spoils app to view details and track your gift.\n\n"
        f"Spoil them properly.\n— The Spoils Team"
    )
    send_mail(
        subject=subject,
        message=body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )


def notify_order_status_change(*, order, previous_status: str | None) -> None:
    if previous_status == order.status:
        return
    if order.status == "pending":
        return
    try:
        send_order_status_email(order=order)
    except Exception:
        logger.exception("Order status email failed for order %s", order.id)
    label = STATUS_LABELS.get(order.status, order.status)
    send_push_notification(
        user=order.user,
        title=f"Order #{order.id} update",
        body=f"Your order is now: {label}",
    )