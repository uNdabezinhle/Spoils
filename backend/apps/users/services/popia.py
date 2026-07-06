from django.utils import timezone

from apps.orders.order_serializers import serialize_order_summary
from apps.reminders.serializers import RecipientSerializer

from ..serializers import AddressSerializer, UserSerializer


def export_user_data(user) -> dict:
    from apps.orders.models import Order
    from apps.reminders.models import Recipient

    orders = Order.objects.filter(user=user).prefetch_related("items")[:100]
    recipients = Recipient.objects.filter(user=user).prefetch_related("occasions")

    return {
        "exported_at": timezone.now().isoformat(),
        "format_version": "1.0",
        "profile": UserSerializer(user).data,
        "addresses": AddressSerializer(user.addresses.all(), many=True).data,
        "orders": [serialize_order_summary(o) for o in orders],
        "recipients": RecipientSerializer(recipients, many=True).data,
        "device_tokens_registered": user.device_tokens.count(),
        "popia_notice": (
            "This export contains personal information held by Spoils in accordance with POPIA. "
            "Keep it secure and do not share it unnecessarily."
        ),
    }


def delete_user_account(user, *, password: str) -> None:
    if not user.check_password(password):
        raise ValueError("Incorrect password.")
    user.delete()