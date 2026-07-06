from decimal import Decimal

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Cart, CartItem
from .serializers import (
    AddToCartSerializer,
    UpdateCartItemSerializer,
    serialize_cart,
    serialize_cart_item,
)


def _get_cart(user):
    cart, _ = Cart.objects.get_or_create(user=user)
    return cart


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def cart_detail(request):
    cart = _get_cart(request.user)
    return Response(serialize_cart(cart))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cart_add_item(request):
    serializer = AddToCartSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data
    cart = _get_cart(request.user)

    customisation = data.get("customisation") or {}
    item, created = CartItem.objects.get_or_create(
        cart=cart,
        product_id=data["product_id"],
        defaults={"quantity": data["quantity"], "customisation_details": customisation},
    )
    if not created:
        item.quantity += data["quantity"]
        if customisation:
            item.customisation_details = customisation
        item.save()

    cart.save()
    return Response(serialize_cart_item(item), status=status.HTTP_201_CREATED)


@api_view(["PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def cart_item_detail(request, pk):
    cart = _get_cart(request.user)
    try:
        item = cart.items.select_related("product").get(pk=pk)
    except CartItem.DoesNotExist:
        return Response({"detail": "Cart item not found."}, status=404)

    if request.method == "DELETE":
        item.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = UpdateCartItemSerializer(data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    data = serializer.validated_data

    if "quantity" in data:
        item.quantity = data["quantity"]
    if "customisation" in data:
        customisation = data["customisation"]
        wrapping_id = customisation.get("wrapping_option_id")
        if wrapping_id:
            from apps.products.models import WrappingOption

            try:
                wrap = WrappingOption.objects.get(pk=wrapping_id, is_active=True)
                customisation["wrapping_name"] = wrap.name
                customisation["ribbon_color"] = wrap.ribbon_color
                customisation["wrapping_price"] = str(wrap.price)
            except WrappingOption.DoesNotExist:
                return Response({"customisation": "Invalid wrapping option."}, status=400)
        item.customisation_details = customisation

    item.save()
    cart.save()
    return Response(serialize_cart_item(item))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cart_clear(request):
    cart = _get_cart(request.user)
    cart.items.all().delete()
    return Response({"detail": "Cart cleared."})


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