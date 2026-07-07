import logging

from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


def send_reminder_email(*, user, recipient_name: str, occasion_type: str, occasion_date, days_until: int) -> None:
    subject = f"Time to spoil {recipient_name} — Spoils reminder"
    body = (
        f"Hi {user.first_name or 'there'},\n\n"
        f"{recipient_name}'s {occasion_type} is coming up on {occasion_date} "
        f"({days_until} day{'s' if days_until != 1 else ''} away).\n\n"
        f"You've still got time to find something thoughtful and spoil them properly.\n"
        f"Open the Spoils app to browse gifts.\n\n"
        f"Spoil them properly.\n— The Spoils Team"
    )
    send_mail(
        subject=subject,
        message=body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )


def send_push_notification(
    *,
    user,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    """Send FCM push when credentials are configured; otherwise log only."""
    from spoil.services.push import send_fcm_to_tokens

    tokens = list(user.device_tokens.values_list("token", flat=True))
    if not tokens:
        return 0
    return send_fcm_to_tokens(tokens=tokens, title=title, body=body, data=data)