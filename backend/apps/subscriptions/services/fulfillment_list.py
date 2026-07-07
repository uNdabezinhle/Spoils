from apps.orders.models import Order


def list_subscription_fulfillments(*, user) -> list[dict]:
    orders = (
        Order.objects.filter(user=user, subscription_id__isnull=False)
        .prefetch_related("items__product")
        .order_by("-created_at")[:24]
    )
    results = []
    for order in orders:
        item = order.items.first()
        results.append(
            {
                "order_id": order.id,
                "subscription_id": order.subscription_id,
                "status": order.status,
                "delivery_date": order.delivery_date.isoformat(),
                "total_amount": str(order.total_amount),
                "created_at": order.created_at.isoformat(),
                "product_name": item.product.name if item else "Spoil Box",
                "product_image_url": item.product.image_url if item else "",
            }
        )
    return results