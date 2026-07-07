from rest_framework import serializers

from .models import LoyaltyAccount, PointsLedgerEntry


class PointsLedgerEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = PointsLedgerEntry
        fields = ("id", "entry_type", "points", "balance_after", "description", "created_at")


class LoyaltyAccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = LoyaltyAccount
        fields = ("balance", "lifetime_earned", "updated_at")