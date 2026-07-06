from decimal import Decimal

from .models import Order, OrderItem
from .serializers import line_unit_total


STATUS_STEPS = ["paid", "processing", "shipped", "delivered"]
STATUS_LABELS = {
    "pending": "Awaiting payment",
    "paid": "Ordered",
    "processing": "Processing",
    "shipped": "Shipped",
    "delivered": "Delivered",
    "cancelled": "Cancelled",
}


def _serialize_order_item(item: OrderItem) -> dict:
    return {
        "id": item.id,
        "product_id": item.product_id,
        "product_name": item.product.name,
        "product_slug": item.product.slug,
        "product_image_url": item.product.image_url,
        "quantity": item.quantity,
        "unit_price": str(item.unit_price),
        "line_total": str(item.unit_price * item.quantity),
        "customisation_details": item.customisation_details,
    }


def serialize_order_summary(order: Order) -> dict:
    return {
        "id": order.id,
        "status": order.status,
        "status_label": STATUS_LABELS.get(order.status, order.status),
        "total_amount": str(order.total_amount),
        "delivery_date": order.delivery_date.isoformat(),
        "delivery_type": order.delivery_type,
        "created_at": order.created_at.isoformat(),
        "item_count": order.items.count(),
    }


def serialize_order_detail(order: Order) -> dict:
    items = [_serialize_order_item(i) for i in order.items.select_related("product")]
    subtotal = sum(Decimal(i["line_total"]) for i in items)

    timeline = []
    if order.status == "pending":
        timeline = [{"status": "pending", "label": STATUS_LABELS["pending"], "completed": False}]
    elif order.status == "cancelled":
        timeline = []
    else:
        current_step = STATUS_STEPS.index(order.status) if order.status in STATUS_STEPS else 0
        timeline = [
            {"status": s, "label": STATUS_LABELS[s], "completed": STATUS_STEPS.index(s) <= current_step}
            for s in STATUS_STEPS
        ]

    return {
        **serialize_order_summary(order),
        "delivery_address": order.delivery_address,
        "paystack_reference": order.paystack_reference,
        "items": items,
        "subtotal": str(subtotal),
        "timeline": timeline,
        "promo_code": order.promo_code.code if order.promo_code else None,
    }


def serialize_receipt(order: Order) -> dict:
    detail = serialize_order_detail(order)
    detail["receipt_title"] = f"Spoils Order #{order.id}"
    detail["tagline"] = "Spoil them properly."
    detail["customer_email"] = order.user.email
    detail["customer_name"] = order.user.get_full_name() or order.user.email
    return detail