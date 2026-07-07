from datetime import datetime
from decimal import Decimal

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.orders.services.paystack import PaystackError

from .models import GroupGift, GroupGiftContribution
from .serializers import GroupGiftSerializer
from .services.checkout import create_group_gift_from_cart, initiate_contribution, verify_contribution


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def group_gift_list(request):
    if request.method == "GET":
        gifts = GroupGift.objects.filter(organizer=request.user).prefetch_related("contributions")
        return Response(GroupGiftSerializer(gifts, many=True).data)

    title = request.data.get("title", "").strip()
    if not title:
        return Response({"detail": "title is required."}, status=400)
    address_id = request.data.get("address_id")
    delivery_date_str = request.data.get("delivery_date")
    if not address_id or not delivery_date_str:
        return Response({"detail": "address_id and delivery_date are required."}, status=400)
    try:
        delivery_date = datetime.strptime(delivery_date_str, "%Y-%m-%d").date()
    except ValueError:
        return Response({"delivery_date": "Use YYYY-MM-DD format."}, status=400)

    try:
        gift = create_group_gift_from_cart(
            user=request.user,
            title=title,
            recipient_name=request.data.get("recipient_name", ""),
            message=request.data.get("message", ""),
            address_id=int(address_id),
            delivery_date=delivery_date,
            delivery_type=request.data.get("delivery_type", "standard"),
        )
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)

    return Response(GroupGiftSerializer(gift).data, status=status.HTTP_201_CREATED)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def group_gift_detail(request, pk):
    try:
        gift = GroupGift.objects.prefetch_related("contributions").get(pk=pk, organizer=request.user)
    except GroupGift.DoesNotExist:
        return Response({"detail": "Group gift not found."}, status=404)
    return Response(GroupGiftSerializer(gift).data)


@api_view(["GET"])
@permission_classes([AllowAny])
def group_gift_public(request, token):
    try:
        gift = GroupGift.objects.prefetch_related("contributions").get(share_token=token)
    except GroupGift.DoesNotExist:
        return Response({"detail": "Group gift not found."}, status=404)
    return Response(GroupGiftSerializer(gift).data)


@api_view(["POST"])
@permission_classes([AllowAny])
def contribute_initiate(request, token):
    try:
        gift = GroupGift.objects.get(share_token=token)
    except GroupGift.DoesNotExist:
        return Response({"detail": "Group gift not found."}, status=404)

    amount = Decimal(str(request.data.get("amount", "0")))
    contributor_name = request.data.get("contributor_name", "").strip()
    contributor_email = request.data.get("contributor_email", "").strip()
    if not contributor_name or not contributor_email:
        return Response({"detail": "contributor_name and contributor_email are required."}, status=400)

    user = request.user if request.user.is_authenticated else None
    try:
        contribution, payment = initiate_contribution(
            group_gift=gift,
            amount=amount,
            contributor_name=contributor_name,
            contributor_email=contributor_email,
            user=user,
            message=request.data.get("message", ""),
        )
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    except PaystackError as exc:
        return Response({"detail": str(exc)}, status=502)

    return Response({**payment, "contribution_id": contribution.id}, status=status.HTTP_201_CREATED)


@api_view(["POST"])
@permission_classes([AllowAny])
def contribute_verify(request):
    contribution_id = request.data.get("contribution_id")
    reference = request.data.get("reference", "").strip()
    if not contribution_id or not reference:
        return Response({"detail": "contribution_id and reference are required."}, status=400)

    try:
        contribution = GroupGiftContribution.objects.select_related("group_gift").get(pk=contribution_id)
    except GroupGiftContribution.DoesNotExist:
        return Response({"detail": "Contribution not found."}, status=404)

    try:
        verify_contribution(contribution=contribution, reference=reference)
    except (ValueError, PaystackError) as exc:
        return Response({"detail": str(exc)}, status=400)

    gift = contribution.group_gift
    gift.refresh_from_db()
    return Response(
        {
            "detail": "Contribution received. Thank you!",
            "group_gift": GroupGiftSerializer(gift).data,
        }
    )