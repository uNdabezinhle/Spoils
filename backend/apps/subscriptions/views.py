from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from apps.orders.services.paystack import PaystackError

from .models import SubscriptionPlan, UserSubscription
from .serializers import SubscriptionPlanSerializer, UserSubscriptionSerializer
from .services.billing import initiate_subscription_payment, verify_subscription_payment


@api_view(["GET"])
@permission_classes([AllowAny])
def plan_list(request):
    plans = SubscriptionPlan.objects.filter(is_active=True)
    return Response(SubscriptionPlanSerializer(plans, many=True).data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_subscriptions(request):
    subs = UserSubscription.objects.filter(user=request.user).select_related("plan")
    return Response(UserSubscriptionSerializer(subs, many=True).data)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def subscribe(request):
    serializer = UserSubscriptionSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    plan_id = serializer.validated_data.pop("plan_id")
    occasion_id = request.data.get("occasion_id")
    try:
        plan = SubscriptionPlan.objects.get(pk=plan_id, is_active=True)
    except SubscriptionPlan.DoesNotExist:
        return Response({"detail": "Plan not found."}, status=404)

    try:
        sub, payment = initiate_subscription_payment(
            user=request.user,
            plan=plan,
            recipient_name=serializer.validated_data.get("recipient_name", ""),
            notes=serializer.validated_data.get("notes", ""),
            occasion_id=int(occasion_id) if occasion_id else None,
        )
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    except PaystackError as exc:
        return Response({"detail": str(exc)}, status=502)

    return Response(
        {
            **payment,
            "subscription": UserSubscriptionSerializer(sub).data,
        },
        status=status.HTTP_201_CREATED,
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def subscribe_verify(request):
    subscription_id = request.data.get("subscription_id")
    reference = request.data.get("reference", "").strip()
    if not subscription_id or not reference:
        return Response({"detail": "subscription_id and reference are required."}, status=400)

    try:
        sub = UserSubscription.objects.select_related("plan").get(pk=subscription_id, user=request.user)
    except UserSubscription.DoesNotExist:
        return Response({"detail": "Subscription not found."}, status=404)

    try:
        sub = verify_subscription_payment(sub=sub, reference=reference)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=400)
    except PaystackError as exc:
        return Response({"detail": str(exc)}, status=502)

    return Response(
        {
            "detail": "Subscription activated.",
            "subscription": UserSubscriptionSerializer(sub).data,
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def subscription_fulfillments(request):
    from .services.fulfillment_list import list_subscription_fulfillments

    return Response({"fulfillments": list_subscription_fulfillments(user=request.user)})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def cancel_subscription(request, pk):
    try:
        sub = UserSubscription.objects.get(pk=pk, user=request.user)
    except UserSubscription.DoesNotExist:
        return Response({"detail": "Subscription not found."}, status=404)
    sub.status = "cancelled"
    sub.save(update_fields=["status"])
    return Response(UserSubscriptionSerializer(sub).data)