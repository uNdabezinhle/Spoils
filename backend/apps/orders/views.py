from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def cart_detail(request):
    from .models import Cart

    cart, _ = Cart.objects.get_or_create(user=request.user)
    items = [
        {
            "id": item.id,
            "product_id": item.product_id,
            "product_name": item.product.name,
            "quantity": item.quantity,
            "unit_price": str(item.product.base_price),
            "customisation_details": item.customisation_details,
        }
        for item in cart.items.select_related("product").all()
    ]
    return Response({"id": cart.id, "items": items})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def order_list(request):
    orders = request.user.orders.all()[:50]
    data = [
        {
            "id": o.id,
            "status": o.status,
            "total_amount": str(o.total_amount),
            "delivery_date": o.delivery_date.isoformat(),
            "created_at": o.created_at.isoformat(),
        }
        for o in orders
    ]
    return Response(data)