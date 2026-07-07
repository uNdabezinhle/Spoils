from datetime import date, datetime, timedelta

from django.db import transaction
from django.utils import timezone

from apps.orders.services.checkout import create_order_for_product, mark_order_paid
from apps.orders.services.paystack import PaystackError, charge_authorization, generate_reference
from apps.subscriptions.models import UserSubscription

from ..models import AutoGiftProposal, Occasion, ReminderLog
from ..services.notifications import send_push_notification
from ..services.suggestions import suggest_gifts_for_occasion
from ..utils import next_occurrence_on

APPROVAL_WINDOW_DAYS = 7
APPROVAL_EXPIRY_DAYS_BEFORE = 2


def _resolve_auto_send_address_id(*, user, occasion: Occasion) -> int | None:
    if occasion.surprise_address_id:
        from apps.users.models import Address

        if Address.objects.filter(user=user, pk=occasion.surprise_address_id).exists():
            return occasion.surprise_address_id
    from apps.users.models import Address

    default = Address.objects.filter(user=user, is_default=True).first()
    if default:
        return default.id
    fallback = Address.objects.filter(user=user).order_by("-created_at").first()
    return fallback.id if fallback else None


def _matching_auto_subscription(*, user, occasion: Occasion) -> UserSubscription | None:
    subs = UserSubscription.objects.filter(
        user=user,
        status="active",
        plan__model_type="occasion_auto",
    ).select_related("plan")
    for sub in subs:
        if sub.occasion_id == occasion.id:
            return sub
        if sub.recipient_name and sub.recipient_name.lower() == occasion.recipient.name.lower():
            return sub
    return None


def _serialize_proposal(proposal: AutoGiftProposal) -> dict:
    product = proposal.suggested_product
    return {
        "id": proposal.id,
        "occasion_id": proposal.occasion_id,
        "status": proposal.status,
        "delivery_date": proposal.delivery_date.isoformat(),
        "expires_at": proposal.expires_at.isoformat(),
        "recipient_name": proposal.occasion.recipient.name,
        "occasion_type": proposal.occasion.type,
        "occasion_type_label": proposal.occasion.get_type_display(),
        "product": {
            "id": product.id,
            "name": product.name,
            "slug": product.slug,
            "base_price": str(product.base_price),
            "image_url": product.image_url,
        },
        "order_id": proposal.order_id,
    }


def get_pending_proposal(*, user, occasion: Occasion) -> AutoGiftProposal | None:
    today = timezone.localdate()
    return (
        AutoGiftProposal.objects.filter(
            user=user,
            occasion=occasion,
            status="pending_approval",
            expires_at__gte=timezone.now(),
            delivery_date__gte=today,
        )
        .select_related("suggested_product", "occasion__recipient")
        .order_by("-created_at")
        .first()
    )


def serialize_pending_proposal(*, user, occasion: Occasion) -> dict | None:
    proposal = get_pending_proposal(user=user, occasion=occasion)
    if not proposal:
        return None
    return _serialize_proposal(proposal)


@transaction.atomic
def create_proposal_for_occasion(*, occasion: Occasion, subscription: UserSubscription | None = None) -> AutoGiftProposal | None:
    user = occasion.recipient.user
    today = timezone.localdate()
    next_date = next_occurrence_on(occasion.date, today=today)

    if ReminderLog.objects.filter(occasion=occasion, status="skipped", skip_year=next_date.year).exists():
        return None
    if occasion.snoozed_until and today <= occasion.snoozed_until:
        return None
    if occasion.surprise_mode_enabled:
        return None

    approval_start = next_date - timedelta(days=APPROVAL_WINDOW_DAYS)
    if today < approval_start or today > next_date:
        return None

    if AutoGiftProposal.objects.filter(
        occasion=occasion,
        delivery_date=next_date,
        status__in=["pending_approval", "ordered", "approved"],
    ).exists():
        return None

    suggestions = suggest_gifts_for_occasion(occasion=occasion, user=user, limit=1)
    if not suggestions:
        return None

    from apps.products.models import Product

    product = Product.objects.get(pk=suggestions[0]["id"])
    expires_at = timezone.make_aware(
        datetime.combine(
            next_date - timedelta(days=APPROVAL_EXPIRY_DAYS_BEFORE),
            datetime.max.time().replace(microsecond=0),
        )
    )

    proposal = AutoGiftProposal.objects.create(
        user=user,
        occasion=occasion,
        subscription=subscription or _matching_auto_subscription(user=user, occasion=occasion),
        suggested_product=product,
        delivery_date=next_date,
        expires_at=expires_at,
    )

    if occasion.auto_send_enabled:
        address_id = _resolve_auto_send_address_id(user=user, occasion=occasion)
        if address_id:
            try:
                approve_proposal(proposal=proposal, address_id=address_id)
                send_push_notification(
                    user=user,
                    title=f"Gift sent for {occasion.recipient.name}",
                    body=f"Auto-send picked {product.name}. We'll deliver on {next_date}.",
                    data={"type": "order_status", "occasion_id": str(occasion.id)},
                )
                return proposal
            except ValueError:
                pass

    send_push_notification(
        user=user,
        title=f"Approve gift for {occasion.recipient.name}?",
        body=f"We picked {product.name} for their {occasion.get_type_display().lower()}. Tap to approve.",
        data={"type": "auto_gift_approval", "occasion_id": str(occasion.id), "proposal_id": str(proposal.id)},
    )
    return proposal


@transaction.atomic
def approve_proposal(*, proposal: AutoGiftProposal, address_id: int, product_id: int | None = None) -> dict:
    if proposal.status != "pending_approval":
        raise ValueError("This proposal is no longer pending approval.")
    if proposal.expires_at < timezone.now():
        proposal.status = "expired"
        proposal.save(update_fields=["status"])
        raise ValueError("This approval window has expired.")

    from apps.products.models import Product

    product = proposal.suggested_product
    if product_id and product_id != product.id:
        product = Product.objects.get(pk=product_id, is_active=True)

    order = create_order_for_product(
        proposal.user,
        product=product,
        address_id=address_id,
        delivery_date=proposal.delivery_date,
        is_anonymous_gift=proposal.occasion.gift_anonymously,
        occasion_id=proposal.occasion_id,
    )

    charged = False
    sub = proposal.subscription or _matching_auto_subscription(user=proposal.user, occasion=proposal.occasion)
    if sub and sub.paystack_authorization_code:
        reference = generate_reference(order.id)
        amount_cents = int(order.total_amount * 100)
        try:
            result = charge_authorization(
                email=proposal.user.email,
                amount_cents=amount_cents,
                authorization_code=sub.paystack_authorization_code,
                reference=reference,
                metadata={"order_id": order.id, "auto_gift_proposal_id": proposal.id},
            )
            if result.get("demo_mode") or result.get("status") == "success":
                mark_order_paid(order, reference)
                charged = True
        except PaystackError as exc:
            order.delete()
            raise ValueError(str(exc)) from exc
    else:
        mark_order_paid(order, order.paystack_reference)
        charged = True

    if not charged:
        order.delete()
        raise ValueError("Payment could not be completed.")

    proposal.status = "ordered"
    proposal.order = order
    proposal.approved_at = timezone.now()
    proposal.suggested_product = product
    proposal.save(update_fields=["status", "order", "approved_at", "suggested_product"])

    ReminderLog.objects.create(
        occasion=proposal.occasion,
        status="acted_on",
        chosen_product=product,
    )

    send_push_notification(
        user=proposal.user,
        title=f"Gift approved for {proposal.occasion.recipient.name}",
        body=f"Order #{order.id} is confirmed. We'll deliver on {proposal.delivery_date}.",
        data={"type": "order_status", "order_id": str(order.id), "status": order.status},
    )
    return {"proposal": _serialize_proposal(proposal), "order_id": order.id}


@transaction.atomic
def reject_proposal(*, proposal: AutoGiftProposal) -> AutoGiftProposal:
    if proposal.status != "pending_approval":
        raise ValueError("This proposal is no longer pending approval.")
    proposal.status = "rejected"
    proposal.save(update_fields=["status"])
    ReminderLog.objects.create(occasion=proposal.occasion, status="skipped", skip_year=proposal.delivery_date.year)
    return proposal