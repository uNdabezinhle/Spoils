from datetime import timedelta

from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import SubscriptionPlan, UserSubscription
from .serializers import SubscriptionPlanSerializer, UserSubscriptionSerializer


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
    try:
        plan = SubscriptionPlan.objects.get(pk=plan_id, is_active=True)
    except SubscriptionPlan.DoesNotExist:
        return Response({"detail": "Plan not found."}, status=404)

    if UserSubscription.objects.filter(user=request.user, plan=plan, status="active").exists():
        return Response({"detail": "You already have an active subscription to this plan."}, status=400)

    sub = UserSubscription.objects.create(
        user=request.user,
        plan=plan,
        recipient_name=serializer.validated_data.get("recipient_name", ""),
        notes=serializer.validated_data.get("notes", ""),
        next_billing_date=timezone.localdate() + timedelta(days=30),
    )
    return Response(UserSubscriptionSerializer(sub).data, status=status.HTTP_201_CREATED)


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