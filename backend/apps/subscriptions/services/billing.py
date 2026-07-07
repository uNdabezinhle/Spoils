from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.orders.services.paystack import (
    PaystackError,
    charge_authorization,
    generate_subscription_reference,
    initialize_transaction,
    is_demo_mode,
    verify_transaction,
)

from ..models import SubscriptionPlan, UserSubscription


@transaction.atomic
def initiate_subscription_payment(
    *,
    user,
    plan: SubscriptionPlan,
    recipient_name: str = "",
    notes: str = "",
    occasion_id: int | None = None,
) -> tuple[UserSubscription, dict]:
    if UserSubscription.objects.filter(user=user, plan=plan, status="active").exists():
        raise ValueError("You already have an active subscription to this plan.")

    occasion = None
    if occasion_id:
        from apps.reminders.models import Occasion

        try:
            occasion = Occasion.objects.select_related("recipient").get(
                pk=occasion_id,
                recipient__user=user,
            )
        except Occasion.DoesNotExist:
            raise ValueError("Occasion not found.")
        if not recipient_name:
            recipient_name = occasion.recipient.name

    sub = UserSubscription.objects.create(
        user=user,
        plan=plan,
        status="pending_payment",
        recipient_name=recipient_name,
        notes=notes,
        occasion=occasion,
    )
    reference = generate_subscription_reference(sub.id)
    sub.paystack_reference = reference
    sub.save(update_fields=["paystack_reference"])

    amount_cents = int(plan.price_monthly * 100)
    payment = initialize_transaction(
        email=user.email,
        amount_cents=amount_cents,
        reference=reference,
        metadata={"subscription_id": sub.id, "plan_slug": plan.slug},
    )
    payment["subscription_id"] = sub.id
    payment["amount"] = str(plan.price_monthly)
    payment["public_key"] = settings.PAYSTACK_PUBLIC_KEY
    return sub, payment


@transaction.atomic
def activate_subscription(*, sub: UserSubscription, reference: str, authorization_code: str = "") -> UserSubscription:
    if sub.status == "active":
        return sub

    sub.status = "active"
    sub.paystack_reference = reference
    sub.last_payment_reference = reference
    sub.last_payment_at = timezone.now()
    sub.next_billing_date = timezone.localdate() + timedelta(days=30)
    if authorization_code:
        sub.paystack_authorization_code = authorization_code
    sub.save(
        update_fields=[
            "status",
            "paystack_reference",
            "last_payment_reference",
            "last_payment_at",
            "next_billing_date",
            "paystack_authorization_code",
        ]
    )
    return sub


def verify_subscription_payment(*, sub: UserSubscription, reference: str) -> UserSubscription:
    if sub.paystack_reference != reference:
        raise ValueError("Reference mismatch.")

    result = verify_transaction(reference)
    if result.get("demo_mode") or result.get("status") == "success":
        return activate_subscription(
            sub=sub,
            reference=reference,
            authorization_code=result.get("authorization_code", ""),
        )
    raise PaystackError("Payment not completed.")


@transaction.atomic
def renew_subscription(sub: UserSubscription) -> bool:
    if sub.status != "active" or not sub.next_billing_date:
        return False
    if sub.next_billing_date > timezone.localdate():
        return False

    reference = generate_subscription_reference(sub.id)
    amount_cents = int(sub.plan.price_monthly * 100)

    try:
        if sub.paystack_authorization_code:
            result = charge_authorization(
                email=sub.user.email,
                amount_cents=amount_cents,
                authorization_code=sub.paystack_authorization_code,
                reference=reference,
                metadata={"subscription_id": sub.id, "renewal": True},
            )
        elif is_demo_mode():
            result = {"status": "success", "reference": reference, "demo_mode": True}
        else:
            sub.status = "paused"
            sub.save(update_fields=["status"])
            return False
    except PaystackError:
        sub.status = "paused"
        sub.save(update_fields=["status"])
        return False

    if result.get("demo_mode") or result.get("status") == "success":
        sub.last_payment_reference = reference
        sub.last_payment_at = timezone.now()
        sub.next_billing_date = timezone.localdate() + timedelta(days=30)
        if result.get("authorization_code"):
            sub.paystack_authorization_code = result["authorization_code"]
        sub.save(
            update_fields=[
                "last_payment_reference",
                "last_payment_at",
                "next_billing_date",
                "paystack_authorization_code",
            ]
        )
        return True

    sub.status = "paused"
    sub.save(update_fields=["status"])
    return False