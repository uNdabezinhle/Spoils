from datetime import datetime

from django.views.decorators.csrf import csrf_exempt
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import Cart, CartItem, Order
from .order_serializers import serialize_order_detail, serialize_order_summary, serialize_receipt
from .serializers import (
    AddToCartSerializer,
    UpdateCartItemSerializer,
    serialize_cart,
    serialize_cart_item,
)
from .services.checkout import (
    calculate_order_totals,
    create_order_from_cart,
    initiate_payment,
    mark_order_paid,
    reorder_to_cart,
)
from .services.paystack import PaystackError, is_demo_mode, verify_transaction, verify_webhook_signature


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


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def checkout_preview(request):
    """Return order totals before payment."""
    cart = _get_cart(request.user)
    if not cart.items.exists():
        return Response({"detail": "Your cart is empty."}, status=400)

    delivery_type = request.data.get("delivery_type", "standard")
    promo_code = request.data.get("promo_code")

    from .models import PromoCode
    from django.utils import timezone

    promo = None
    if promo_code:
        promo = PromoCode.objects.filter(code__iexact=promo_code.strip(), is_active=True).first()
        if not promo:
            return Response({"promo_code": "Invalid promo code."}, status=400)
        if promo.expires_at and promo.expires_at < timezone.now():
            return Response({"promo_code": "This promo code has expired."}, status=400)

    totals = calculate_order_totals(cart, delivery_type, promo)
    return Response({
        "subtotal": str(totals["subtotal"]),
        "delivery_fee": str(totals["delivery_fee"]),
        "discount": str(totals["discount"]),
        "total": str(totals["total"]),
        "demo_mode": is_demo_mode(),
    })


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def checkout_initiate(request):
    address_id = request.data.get("address_id")
    delivery_date_str = request.data.get("delivery_date")
    delivery_type = request.data.get("delivery_type", "standard")
    promo_code = request.data.get("promo_code")

    if not address_id or not delivery_date_str:
        return Response({"detail": "address_id and delivery_date are required."}, status=400)

    try:
        delivery_date = datetime.strptime(delivery_date_str, "%Y-%m-%d").date()
    except ValueError:
        return Response({"delivery_date": "Use YYYY-MM-DD format."}, status=400)

    try:
        order = create_order_from_cart(
            request.user,
            address_id=int(address_id),
            delivery_date=delivery_date,
            delivery_type=delivery_type,
            promo_code=promo_code,
        )
        payment = initiate_payment(order)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    except PaystackError as exc:
        return Response({"detail": str(exc)}, status=502)

    return Response({
        **payment,
        "order": serialize_order_summary(order),
    }, status=status.HTTP_201_CREATED)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def checkout_verify(request):
    reference = request.data.get("reference", "").strip()
    order_id = request.data.get("order_id")

    if not reference:
        return Response({"detail": "reference is required."}, status=400)

    try:
        order = Order.objects.get(pk=order_id, user=request.user)
    except (Order.DoesNotExist, TypeError, ValueError):
        try:
            order = Order.objects.get(paystack_reference=reference, user=request.user)
        except Order.DoesNotExist:
            return Response({"detail": "Order not found."}, status=404)

    if order.paystack_reference != reference:
        return Response({"detail": "Reference mismatch."}, status=400)

    try:
        result = verify_transaction(reference)
    except PaystackError as exc:
        return Response({"detail": str(exc)}, status=502)

    if result.get("demo_mode") or result.get("status") == "success":
        order = mark_order_paid(order, reference)
        return Response({
            "detail": "Payment successful.",
            "order": serialize_order_detail(order),
        })

    return Response({"detail": "Payment not completed.", "status": result.get("status")}, status=400)


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def paystack_webhook(request):
    signature = request.headers.get("x-paystack-signature", "")
    if not verify_webhook_signature(payload=request.body, signature=signature):
        return Response({"detail": "Invalid signature."}, status=401)

    event = request.data.get("event")
    data = request.data.get("data", {})
    if event == "charge.success":
        reference = data.get("reference")
        if reference:
            try:
                order = Order.objects.get(paystack_reference=reference)
                mark_order_paid(order, reference)
            except Order.DoesNotExist:
                pass
    return Response({"status": "ok"})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def order_list(request):
    orders = request.user.orders.prefetch_related("items").all()[:50]
    return Response([serialize_order_summary(o) for o in orders])


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def order_detail(request, pk):
    try:
        order = Order.objects.prefetch_related("items__product").get(pk=pk, user=request.user)
    except Order.DoesNotExist:
        return Response({"detail": "Order not found."}, status=404)
    return Response(serialize_order_detail(order))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def order_receipt(request, pk):
    try:
        order = Order.objects.prefetch_related("items__product").get(pk=pk, user=request.user)
    except Order.DoesNotExist:
        return Response({"detail": "Order not found."}, status=404)
    return Response(serialize_receipt(order))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def order_reorder(request, pk):
    try:
        order = Order.objects.prefetch_related("items__product").get(pk=pk, user=request.user)
    except Order.DoesNotExist:
        return Response({"detail": "Order not found."}, status=404)

    count = reorder_to_cart(order)
    return Response({"detail": f"{count} item(s) added to cart.", "items_added": count})