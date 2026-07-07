from datetime import timedelta
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.orders.models import Order, OrderItem
from apps.orders.services.checkout import mark_order_paid
from apps.products.models import Product
from apps.reminders.services.notifications import send_push_notification

from ..models import UserSubscription


def _default_address_for_user(user):
    from apps.users.models import Address

    address = Address.objects.filter(user=user, is_default=True).first()
    if not address:
        address = Address.objects.filter(user=user).order_by("-created_at").first()
    return address


def _pick_fulfillment_product(*, sub: UserSubscription) -> Product | None:
    budget = sub.plan.price_monthly
    qs = Product.objects.filter(is_active=True, base_price__lte=budget).order_by("-is_featured", "-is_popular")
    if sub.plan.model_type == "someone_to_spoil" and sub.occasion_id and sub.occasion:
        occasion_type = sub.occasion.type
        if occasion_type:
            match = qs.filter(occasion=occasion_type).first()
            if match:
                return match
    return qs.first()


@transaction.atomic
def fulfill_subscription_renewal(*, sub: UserSubscription, payment_reference: str) -> Order | None:
    if sub.plan.model_type not in ("spoil_box", "someone_to_spoil"):
        return None

    address = _default_address_for_user(sub.user)
    if not address:
        return None

    product = _pick_fulfillment_product(sub=sub)
    if not product:
        return None

    delivery_date = timezone.localdate() + timedelta(days=5)
    address_payload = {
        "label": address.label,
        "recipient_name": sub.recipient_name or address.recipient_name,
        "phone": address.phone,
        "street_address": address.street_address,
        "suburb": address.suburb,
        "city": address.city,
        "province": address.province,
        "postal_code": address.postal_code,
    }

    order = Order.objects.create(
        user=sub.user,
        status="pending",
        total_amount=product.base_price,
        delivery_address=address_payload,
        delivery_date=delivery_date,
        delivery_type="standard",
        subscription_id=sub.id,
        paystack_reference=payment_reference,
    )
    OrderItem.objects.create(
        order=order,
        product=product,
        quantity=1,
        unit_price=product.base_price,
        customisation_details={"subscription_fulfillment": sub.plan.slug},
    )
    mark_order_paid(order, payment_reference)
    order.status = "processing"
    order.save(update_fields=["status", "updated_at"])

    label = sub.plan.name
    send_push_notification(
        user=sub.user,
        title=f"Your {label} is on the way",
        body=f"We're preparing {product.name} for delivery around {delivery_date}.",
        data={"type": "order_status", "order_id": str(order.id), "status": order.status},
    )
    return order