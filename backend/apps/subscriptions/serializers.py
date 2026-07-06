from rest_framework import serializers

from .models import SubscriptionPlan, UserSubscription


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = (
            "id",
            "name",
            "slug",
            "model_type",
            "tagline",
            "description",
            "price_monthly",
            "image_url",
            "features",
        )


class UserSubscriptionSerializer(serializers.ModelSerializer):
    plan = SubscriptionPlanSerializer(read_only=True)
    plan_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = UserSubscription
        fields = (
            "id",
            "plan",
            "plan_id",
            "status",
            "recipient_name",
            "started_at",
            "next_billing_date",
            "notes",
        )
        read_only_fields = ("id", "status", "started_at", "next_billing_date")