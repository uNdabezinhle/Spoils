from decimal import Decimal

from django.db import transaction

from ..models import LoyaltyAccount, PointsLedgerEntry

POINTS_PER_RAND = 1
POINTS_PER_RAND_REDEEM = 10  # 100 points = R10
MAX_REDEEM_PERCENT = Decimal("0.50")


def get_or_create_account(user) -> LoyaltyAccount:
    account, _ = LoyaltyAccount.objects.get_or_create(user=user)
    return account


def points_to_discount(points: int) -> Decimal:
    return (Decimal(points) / Decimal(POINTS_PER_RAND_REDEEM)).quantize(Decimal("0.01"))


def discount_to_points(amount: Decimal) -> int:
    return int(amount * POINTS_PER_RAND_REDEEM)


def max_redeemable_points(*, account: LoyaltyAccount, subtotal: Decimal) -> int:
    max_discount = (subtotal * MAX_REDEEM_PERCENT).quantize(Decimal("0.01"))
    max_by_subtotal = discount_to_points(max_discount)
    return min(account.balance, max_by_subtotal)


def validate_points_redemption(*, user, points_to_redeem: int, subtotal: Decimal) -> Decimal:
    if points_to_redeem <= 0:
        return Decimal("0")
    account = get_or_create_account(user)
    allowed = max_redeemable_points(account=account, subtotal=subtotal)
    if points_to_redeem > allowed:
        raise ValueError(f"You can redeem up to {allowed} points on this order.")
    return points_to_discount(points_to_redeem)


@transaction.atomic
def redeem_points(*, user, points: int, order) -> None:
    if points <= 0:
        return
    account = get_or_create_account(user)
    if account.balance < points:
        raise ValueError("Insufficient points.")
    account.balance -= points
    account.save(update_fields=["balance", "updated_at"])
    PointsLedgerEntry.objects.create(
        account=account,
        entry_type="redeem",
        points=-points,
        balance_after=account.balance,
        description=f"Redeemed on order #{order.id}",
        order=order,
    )


@transaction.atomic
def earn_for_order(*, order) -> int:
    items = order.items.select_related("product")
    subtotal = sum(i.unit_price * i.quantity for i in items)
    points = int(subtotal * POINTS_PER_RAND)
    if points <= 0:
        return 0
    account = get_or_create_account(order.user)
    account.balance += points
    account.lifetime_earned += points
    account.save(update_fields=["balance", "lifetime_earned", "updated_at"])
    PointsLedgerEntry.objects.create(
        account=account,
        entry_type="earn",
        points=points,
        balance_after=account.balance,
        description=f"Earned from order #{order.id}",
        order=order,
    )
    return points