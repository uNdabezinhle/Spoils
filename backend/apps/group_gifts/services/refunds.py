from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from apps.orders.services.paystack import PaystackError, refund_transaction

from ..models import GroupGift, GroupGiftContribution


@transaction.atomic
def refund_contribution(*, contribution: GroupGiftContribution) -> GroupGiftContribution:
    if contribution.status != "paid":
        return contribution

    amount_cents = int(contribution.amount * 100)
    if contribution.paystack_reference:
        try:
            refund_transaction(reference=contribution.paystack_reference, amount_cents=amount_cents)
        except PaystackError:
            raise

    contribution.status = "refunded"
    contribution.save(update_fields=["status"])

    gift = contribution.group_gift
    gift.amount_collected = max(Decimal("0"), gift.amount_collected - contribution.amount)
    gift.save(update_fields=["amount_collected", "updated_at"])
    return contribution


@transaction.atomic
def cancel_group_gift(*, group_gift: GroupGift, reason: str = "cancelled") -> GroupGift:
    if group_gift.status in ("ordered", "cancelled"):
        raise ValueError("This group gift can no longer be cancelled.")

    for contribution in group_gift.contributions.filter(status="paid"):
        refund_contribution(contribution=contribution)

    group_gift.status = "cancelled"
    group_gift.save(update_fields=["status", "updated_at"])
    return group_gift


def expire_unfunded_group_gifts() -> dict:
    today = timezone.localdate()
    expired = 0
    gifts = GroupGift.objects.filter(status="open", delivery_date__lt=today)
    for gift in gifts:
        if gift.amount_collected >= gift.target_amount:
            continue
        try:
            cancel_group_gift(group_gift=gift, reason="expired")
            expired += 1
        except (ValueError, PaystackError):
            continue
    return {"expired": expired}