from decimal import Decimal

from django.db.models import Sum

from apps.orders.models import Order, OrderItem
from apps.products.models import Product
from apps.reminders.models import Occasion, Recipient
from apps.subscriptions.models import UserSubscription
from apps.users.models import User


def get_analytics_overview() -> dict:
    paid_statuses = ["paid", "processing", "shipped", "delivered"]
    orders = Order.objects.all()
    paid_orders = orders.filter(status__in=paid_statuses)
    revenue = paid_orders.aggregate(total=Sum("total_amount"))["total"] or Decimal("0")

    top_by_quantity = (
        OrderItem.objects.filter(order__status__in=paid_statuses)
        .values("product__name", "product__slug")
        .annotate(quantity=Sum("quantity"))
        .order_by("-quantity")[:5]
    )

    top_products = []
    for row in top_by_quantity:
        line_revenue = Decimal("0")
        for item in OrderItem.objects.filter(
            order__status__in=paid_statuses,
            product__slug=row["product__slug"],
        ).only("quantity", "unit_price"):
            line_revenue += Decimal(item.quantity) * item.unit_price
        top_products.append(
            {
                "name": row["product__name"],
                "slug": row["product__slug"],
                "quantity": row["quantity"],
                "revenue": str(line_revenue),
            }
        )

    return {
        "users_total": User.objects.count(),
        "orders_total": orders.count(),
        "orders_paid": paid_orders.count(),
        "revenue_total": str(revenue),
        "recipients_total": Recipient.objects.count(),
        "occasions_active": Occasion.objects.filter(is_active=True).count(),
        "subscriptions_active": UserSubscription.objects.filter(status="active").count(),
        "products_active": Product.objects.filter(is_active=True).count(),
        "top_products": top_products,
    }