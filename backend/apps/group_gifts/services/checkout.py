from datetime import date
from decimal import Decimal

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.orders.models import Order, OrderItem
from apps.orders.services.checkout import DELIVERY_FEES, _address_to_dict, mark_order_paid
from apps.orders.services.paystack import (
    PaystackError,
    generate_reference,
    initialize_transaction,
    is_demo_mode,
    verify_transaction,
)
from apps.users.models import Address

from ..models import GroupGift, GroupGiftContribution


def generate_group_reference(contribution_id: int) -> str:
    return f"group_{contribution_id}_{generate_reference(contribution_id).split('_', 2)[-1]}"


@transaction.atomic
def create_group_gift_from_cart(
    *,
    user,
    title: str,
    recipient_name: str = "",
    message: str = "",
    address_id: int,
    delivery_date: date,
    delivery_type: str = "standard",
) -> GroupGift:
    from apps.orders.models import Cart
    from apps.orders.serializers import line_unit_total, serialize_cart

    cart, _ = Cart.objects.get_or_create(user=user)
    if not cart.items.exists():
        raise ValueError("Your cart is empty.")

    try:
        address = user.addresses.get(pk=address_id)
    except Address.DoesNotExist:
        raise ValueError("Delivery address not found.")

    serialized = serialize_cart(cart)
    subtotal = Decimal(serialized["subtotal"])
    delivery_fee = DELIVERY_FEES.get(delivery_type, DELIVERY_FEES["standard"])
    target = subtotal + delivery_fee

    snapshot = []
    for item in cart.items.select_related("product"):
        unit = line_unit_total(item.product, item.customisation_details or {})
        snapshot.append(
            {
                "product_id": item.product_id,
                "product_name": item.product.name,
                "product_slug": item.product.slug,
                "quantity": item.quantity,
                "unit_price": str(unit),
                "customisation_details": item.customisation_details,
            }
        )

    return GroupGift.objects.create(
        organizer=user,
        title=title,
        recipient_name=recipient_name,
        message=message,
        target_amount=target,
        cart_snapshot=snapshot,
        delivery_address=_address_to_dict(address),
        delivery_date=delivery_date,
        delivery_type=delivery_type,
    )


@transaction.atomic
def initiate_contribution(
    *,
    group_gift: GroupGift,
    amount: Decimal,
    contributor_name: str,
    contributor_email: str,
    user=None,
    message: str = "",
) -> tuple[GroupGiftContribution, dict]:
    if group_gift.status != "open":
        raise ValueError("This group gift is no longer accepting contributions.")
    if amount <= 0:
        raise ValueError("Contribution amount must be positive.")
    remaining = group_gift.target_amount - group_gift.amount_collected
    if amount > remaining:
        raise ValueError(f"Maximum contribution is R{remaining}.")

    contribution = GroupGiftContribution.objects.create(
        group_gift=group_gift,
        user=user,
        contributor_name=contributor_name.strip(),
        contributor_email=contributor_email.strip().lower(),
        amount=amount,
        message=message,
    )
    reference = generate_group_reference(contribution.id)
    contribution.paystack_reference = reference
    contribution.save(update_fields=["paystack_reference"])

    payment = initialize_transaction(
        email=contributor_email,
        amount_cents=int(amount * 100),
        reference=reference,
        metadata={"group_gift_id": group_gift.id, "contribution_id": contribution.id},
    )
    payment["contribution_id"] = contribution.id
    payment["amount"] = str(amount)
    payment["public_key"] = settings.PAYSTACK_PUBLIC_KEY
    return contribution, payment


@transaction.atomic
def verify_contribution(*, contribution: GroupGiftContribution, reference: str) -> GroupGiftContribution:
    if contribution.paystack_reference != reference:
        raise ValueError("Reference mismatch.")
    if contribution.status == "paid":
        return contribution

    result = verify_transaction(reference)
    if not (result.get("demo_mode") or result.get("status") == "success"):
        contribution.status = "failed"
        contribution.save(update_fields=["status"])
        raise PaystackError("Payment not completed.")

    contribution.status = "paid"
    contribution.save(update_fields=["status"])

    group_gift = contribution.group_gift
    group_gift.amount_collected += contribution.amount
    group_gift.save(update_fields=["amount_collected", "updated_at"])

    if group_gift.amount_collected >= group_gift.target_amount:
        finalize_group_gift_order(group_gift=group_gift)

    return contribution


@transaction.atomic
def finalize_group_gift_order(*, group_gift: GroupGift) -> Order | None:
    if group_gift.status in ("ordered", "cancelled"):
        return group_gift.order
    if group_gift.amount_collected < group_gift.target_amount:
        return None

    from apps.products.models import Product

    order = Order.objects.create(
        user=group_gift.organizer,
        status="pending",
        total_amount=group_gift.target_amount,
        delivery_address=group_gift.delivery_address,
        delivery_date=group_gift.delivery_date or timezone.localdate(),
        delivery_type=group_gift.delivery_type,
    )
    for item in group_gift.cart_snapshot:
        product = Product.objects.get(pk=item["product_id"])
        OrderItem.objects.create(
            order=order,
            product=product,
            quantity=item["quantity"],
            unit_price=Decimal(item["unit_price"]),
            customisation_details=item.get("customisation_details") or {},
        )

    reference = generate_reference(order.id)
    order.paystack_reference = reference
    order.save(update_fields=["paystack_reference"])
    mark_order_paid(order, reference)

    group_gift.status = "ordered"
    group_gift.order = order
    group_gift.save(update_fields=["status", "order", "updated_at"])

    from apps.orders.models import Cart

    cart = Cart.objects.filter(user=group_gift.organizer).first()
    if cart:
        cart.items.all().delete()

    return order