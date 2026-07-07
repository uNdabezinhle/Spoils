from rest_framework import serializers

from .models import GroupGift, GroupGiftContribution


class GroupGiftContributionSerializer(serializers.ModelSerializer):
    class Meta:
        model = GroupGiftContribution
        fields = (
            "id",
            "contributor_name",
            "amount",
            "status",
            "message",
            "created_at",
        )


class GroupGiftSerializer(serializers.ModelSerializer):
    contributions = GroupGiftContributionSerializer(many=True, read_only=True)
    progress_percent = serializers.IntegerField(read_only=True)
    remaining_amount = serializers.SerializerMethodField()

    class Meta:
        model = GroupGift
        fields = (
            "id",
            "share_token",
            "title",
            "recipient_name",
            "message",
            "target_amount",
            "amount_collected",
            "remaining_amount",
            "progress_percent",
            "status",
            "cart_snapshot",
            "delivery_date",
            "delivery_type",
            "order",
            "contributions",
            "created_at",
        )
        read_only_fields = ("share_token", "amount_collected", "status", "order")

    def get_remaining_amount(self, obj) -> str:
        remaining = max(obj.target_amount - obj.amount_collected, 0)
        return str(remaining)