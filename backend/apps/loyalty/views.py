from decimal import Decimal

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.orders.models import Cart
from apps.orders.serializers import serialize_cart

from .models import PointsLedgerEntry
from .serializers import LoyaltyAccountSerializer, PointsLedgerEntrySerializer
from .services.ledger import (
    get_or_create_account,
    max_redeemable_points,
    points_to_discount,
    validate_points_redemption,
)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def loyalty_me(request):
    account = get_or_create_account(request.user)
    return Response(LoyaltyAccountSerializer(account).data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def loyalty_history(request):
    account = get_or_create_account(request.user)
    entries = PointsLedgerEntry.objects.filter(account=account)[:50]
    return Response(PointsLedgerEntrySerializer(entries, many=True).data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def loyalty_preview_redeem(request):
    points = int(request.data.get("points_to_redeem", 0))
    cart, _ = Cart.objects.get_or_create(user=request.user)
    subtotal = Decimal(serialize_cart(cart)["subtotal"])
    if subtotal <= 0:
        return Response({"detail": "Your cart is empty."}, status=400)
    try:
        discount = validate_points_redemption(user=request.user, points_to_redeem=points, subtotal=subtotal)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    account = get_or_create_account(request.user)
    return Response(
        {
            "points_to_redeem": points,
            "points_discount": str(discount),
            "max_redeemable_points": max_redeemable_points(account=account, subtotal=subtotal),
            "balance": account.balance,
        }
    )