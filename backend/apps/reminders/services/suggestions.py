from apps.orders.models import OrderItem
from apps.products.models import Product
from apps.products.serializers import ProductListSerializer


def _pick_reason(*, product: Product, occasion, purchased_ids: set[int]) -> str:
    occasion_label = occasion.get_type_display().lower()
    if product.occasion == occasion.type:
        return f"Popular for {occasion_label}s like {occasion.recipient.name}'s"
    if product.id in purchased_ids:
        return "You've ordered this before — a safe favourite"
    if product.is_featured:
        return "Staff favourite this season"
    if product.is_popular:
        return "Trending with Spoils customers right now"
    if occasion.recipient.notes:
        return f"A thoughtful match for {occasion.recipient.name}"
    return "Curated for someone special"


def suggest_gifts_for_occasion(*, occasion, user, limit: int = 8) -> list[dict]:
    """Context-aware gift suggestions for an occasion."""
    paid_statuses = ["paid", "processing", "shipped", "delivered"]
    purchased_ids = set(
        OrderItem.objects.filter(
            order__user=user,
            order__status__in=paid_statuses,
        ).values_list("product_id", flat=True)
    )

    primary = list(
        Product.objects.filter(is_active=True, occasion=occasion.type)
        .select_related("category")
        .order_by("-is_featured", "-is_popular", "name")
    )

    scored: list[Product] = []
    seen: set[int] = set()
    for product in primary:
        if product.id in seen:
            continue
        seen.add(product.id)
        scored.append(product)

    if len(scored) < limit:
        extras = (
            Product.objects.filter(is_active=True, is_featured=True)
            .exclude(pk__in=seen)
            .select_related("category")
            .order_by("-is_popular", "name")[: limit - len(scored)]
        )
        for product in extras:
            seen.add(product.id)
            scored.append(product)

    if len(scored) < limit:
        extras = (
            Product.objects.filter(is_active=True)
            .exclude(pk__in=seen)
            .select_related("category")
            .order_by("-is_popular", "name")[: limit - len(scored)]
        )
        scored.extend(extras)

    def sort_key(product: Product) -> tuple:
        repurchase = 0 if product.id in purchased_ids else 1
        return (repurchase, product.is_featured, product.is_popular)

    scored.sort(key=sort_key, reverse=True)
    selected = scored[:limit]
    serialized = ProductListSerializer(selected, many=True).data
    for item, product in zip(serialized, selected):
        item["pick_reason"] = _pick_reason(product=product, occasion=occasion, purchased_ids=purchased_ids)
    return serialized