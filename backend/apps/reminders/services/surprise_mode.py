from datetime import timedelta
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.orders.services.checkout import create_order_for_product, mark_order_paid
from apps.orders.services.paystack import PaystackError, charge_authorization, generate_reference
from apps.subscriptions.models import UserSubscription

from ..models import Occasion, ReminderLog
from ..services.auto_gift import _matching_auto_subscription
from ..services.notifications import send_push_notification
from ..services.suggestions import suggest_gifts_for_occasion
from ..utils import next_occurrence_on

SURPRISE_DAYS_BEFORE = 3


def _pick_product_within_budget(*, occasion, user, budget: Decimal):
    suggestions = suggest_gifts_for_occasion(occasion=occasion, user=user, limit=20)
    for item in suggestions:
        price = Decimal(str(item["base_price"]))
        if price <= budget:
            from apps.products.models import Product

            return Product.objects.get(pk=item["id"])
    return None


@transaction.atomic
def process_surprise_for_occasion(*, occasion: Occasion) -> dict | None:
    if not occasion.surprise_mode_enabled or not occasion.surprise_budget:
        return None
    if not occasion.is_active:
        return None

    user = occasion.recipient.user
    today = timezone.localdate()
    next_date = next_occurrence_on(occasion.date, today=today)

    if ReminderLog.objects.filter(occasion=occasion, status="skipped", skip_year=next_date.year).exists():
        return None
    if occasion.snoozed_until and today <= occasion.snoozed_until:
        return None

    surprise_date = next_date - timedelta(days=SURPRISE_DAYS_BEFORE)
    if today != surprise_date:
        return None

    if ReminderLog.objects.filter(occasion=occasion, status="acted_on", sent_at__year=next_date.year).exists():
        return None

    address_id = occasion.surprise_address_id
    if not address_id:
        default = user.addresses.order_by("id").first()
        if not default:
            return None
        address_id = default.id

    product = _pick_product_within_budget(
        occasion=occasion,
        user=user,
        budget=Decimal(str(occasion.surprise_budget)),
    )
    if not product:
        send_push_notification(
            user=user,
            title="Surprise mode needs your help",
            body=f"No gift fit your R{occasion.surprise_budget} budget for {occasion.recipient.name}. Tap to choose manually.",
            data={"type": "auto_gift_approval", "occasion_id": str(occasion.id)},
        )
        return None

    order = create_order_for_product(
        user,
        product=product,
        address_id=address_id,
        delivery_date=next_date,
        is_anonymous_gift=occasion.gift_anonymously,
        occasion_id=occasion.id,
    )

    sub = _matching_auto_subscription(user=user, occasion=occasion)
    charged = False
    if sub and sub.paystack_authorization_code:
        reference = generate_reference(order.id)
        amount_cents = int(order.total_amount * 100)
        try:
            result = charge_authorization(
                email=user.email,
                amount_cents=amount_cents,
                authorization_code=sub.paystack_authorization_code,
                reference=reference,
                metadata={"order_id": order.id, "surprise_mode": True},
            )
            if result.get("demo_mode") or result.get("status") == "success":
                mark_order_paid(order, reference)
                charged = True
        except PaystackError:
            order.delete()
            return None
    else:
        mark_order_paid(order, order.paystack_reference)
        charged = True

    if not charged:
        order.delete()
        return None

    ReminderLog.objects.create(occasion=occasion, status="acted_on", chosen_product=product)
    sender_label = "Someone special" if occasion.gift_anonymously else "You"
    send_push_notification(
        user=user,
        title=f"Surprise sent for {occasion.recipient.name}!",
        body=f"{sender_label} spoiled them with {product.name} (R{product.base_price}). Order #{order.id} confirmed.",
        data={"type": "order_status", "order_id": str(order.id), "status": order.status},
    )
    return {"order_id": order.id, "product_id": product.id, "anonymous": occasion.gift_anonymously}