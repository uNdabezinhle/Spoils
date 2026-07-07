from datetime import date
from decimal import Decimal

from django.core.mail import send_mail
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.users.models import Address

from ..models import Cart, CartItem, Order, OrderItem, PromoCode
from ..serializers import line_unit_total, serialize_cart
from .paystack import generate_reference, initialize_transaction

DELIVERY_FEES = {
    "standard": Decimal("79.00"),
    "express": Decimal("149.00"),
}


def _address_to_dict(address: Address) -> dict:
    return {
        "id": address.id,
        "label": address.label,
        "recipient_name": address.recipient_name,
        "phone": address.phone,
        "street_address": address.street_address,
        "suburb": address.suburb,
        "city": address.city,
        "province": address.province,
        "postal_code": address.postal_code,
    }


def calculate_order_totals(
    cart,
    delivery_type: str,
    promo: PromoCode | None = None,
    *,
    user=None,
    points_to_redeem: int = 0,
) -> dict:
    serialized = serialize_cart(cart)
    subtotal = Decimal(serialized["subtotal"])
    delivery_fee = DELIVERY_FEES.get(delivery_type, DELIVERY_FEES["standard"])
    discount = Decimal("0")
    if promo:
        discount = (subtotal * Decimal(promo.discount_percent) / Decimal("100")).quantize(Decimal("0.01"))
    points_discount = Decimal("0")
    if user and points_to_redeem > 0:
        from apps.loyalty.services.ledger import validate_points_redemption

        points_discount = validate_points_redemption(
            user=user,
            points_to_redeem=points_to_redeem,
            subtotal=subtotal,
        )
    total = subtotal + delivery_fee - discount - points_discount
    return {
        "subtotal": subtotal,
        "delivery_fee": delivery_fee,
        "discount": discount,
        "points_discount": points_discount,
        "points_to_redeem": points_to_redeem if points_discount > 0 else 0,
        "total": max(total, Decimal("0.01")),
    }


@transaction.atomic
def create_order_from_cart(
    user,
    *,
    address_id: int,
    delivery_date: date,
    delivery_type: str = "standard",
    promo_code: str | None = None,
    points_to_redeem: int = 0,
) -> Order:
    try:
        address = user.addresses.get(pk=address_id)
    except Address.DoesNotExist:
        raise ValueError("Delivery address not found.")

    cart, _ = Cart.objects.get_or_create(user=user)
    if not cart.items.exists():
        raise ValueError("Your cart is empty.")

    promo = None
    if promo_code:
        promo = PromoCode.objects.filter(code__iexact=promo_code.strip(), is_active=True).first()
        if not promo:
            raise ValueError("Invalid promo code.")
        if promo.expires_at and promo.expires_at < timezone.now():
            raise ValueError("This promo code has expired.")

    totals = calculate_order_totals(cart, delivery_type, promo, user=user, points_to_redeem=points_to_redeem)

    order = Order.objects.create(
        user=user,
        status="pending",
        total_amount=totals["total"],
        delivery_address=_address_to_dict(address),
        delivery_date=delivery_date,
        delivery_type=delivery_type,
        promo_code=promo,
        points_redeemed=totals["points_to_redeem"],
        points_discount=totals["points_discount"],
    )

    for item in cart.items.select_related("product"):
        unit_total = line_unit_total(item.product, item.customisation_details or {})
        OrderItem.objects.create(
            order=order,
            product=item.product,
            quantity=item.quantity,
            unit_price=unit_total,
            customisation_details=item.customisation_details,
        )

    reference = generate_reference(order.id)
    order.paystack_reference = reference
    order.save(update_fields=["paystack_reference"])

    return order


def initiate_payment(order: Order) -> dict:
    amount_cents = int(order.total_amount * 100)
    result = initialize_transaction(
        email=order.user.email,
        amount_cents=amount_cents,
        reference=order.paystack_reference,
        metadata={"order_id": order.id},
    )
    result["order_id"] = order.id
    result["amount"] = str(order.total_amount)
    result["public_key"] = settings.PAYSTACK_PUBLIC_KEY
    return result


@transaction.atomic
def create_order_for_product(
    user,
    *,
    product,
    address_id: int,
    delivery_date: date,
    delivery_type: str = "standard",
    quantity: int = 1,
) -> Order:
    try:
        address = user.addresses.get(pk=address_id)
    except Address.DoesNotExist:
        raise ValueError("Delivery address not found.")

    unit_total = line_unit_total(product, {})
    total = unit_total * quantity + DELIVERY_FEES.get(delivery_type, DELIVERY_FEES["standard"])

    order = Order.objects.create(
        user=user,
        status="pending",
        total_amount=max(total, Decimal("0.01")),
        delivery_address=_address_to_dict(address),
        delivery_date=delivery_date,
        delivery_type=delivery_type,
    )
    from ..models import OrderItem

    OrderItem.objects.create(
        order=order,
        product=product,
        quantity=quantity,
        unit_price=unit_total,
        customisation_details={},
    )

    reference = generate_reference(order.id)
    order.paystack_reference = reference
    order.save(update_fields=["paystack_reference"])
    return order


@transaction.atomic
def mark_order_paid(order: Order, reference: str) -> Order:
    if order.status == "paid":
        return order

    previous_status = order.status
    order.status = "paid"
    order.paystack_reference = reference
    order.save(update_fields=["status", "paystack_reference", "updated_at"])

    cart = Cart.objects.filter(user=order.user).first()
    if cart:
        cart.items.all().delete()

    _send_confirmation_email(order)
    from .notifications import notify_order_status_change

    notify_order_status_change(order=order, previous_status=previous_status)

    if order.points_redeemed > 0:
        from apps.loyalty.services.ledger import redeem_points

        redeem_points(user=order.user, points=order.points_redeemed, order=order)
    from apps.loyalty.services.ledger import earn_for_order

    earn_for_order(order=order)
    return order


def _send_confirmation_email(order: Order) -> None:
    user = order.user
    items = order.items.select_related("product")
    lines = [f"- {i.product.name} x{i.quantity} (R{i.unit_price * i.quantity})" for i in items]
    body = (
        f"Hi {user.first_name or 'there'},\n\n"
        f"Thank you for spoiling someone properly! Your order #{order.id} is confirmed.\n\n"
        f"Delivery date: {order.delivery_date}\n"
        f"Total: R{order.total_amount}\n\n"
        f"Items:\n" + "\n".join(lines) + "\n\n"
        f"We'll keep you updated as your gift makes its way.\n\n"
        f"Spoil them properly.\n— The Spoils Team"
    )
    send_mail(
        subject=f"Order #{order.id} confirmed — Spoils",
        message=body,
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=True,
    )


def reorder_to_cart(order: Order) -> int:
    cart, _ = Cart.objects.get_or_create(user=order.user)
    count = 0
    for item in order.items.select_related("product"):
        if not item.product.is_active:
            continue
        cart_item, created = CartItem.objects.get_or_create(
            cart=cart,
            product=item.product,
            defaults={
                "quantity": item.quantity,
                "customisation_details": item.customisation_details,
            },
        )
        if not created:
            cart_item.quantity += item.quantity
            cart_item.customisation_details = item.customisation_details
            cart_item.save()
        count += 1
    return count