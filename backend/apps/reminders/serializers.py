from rest_framework import serializers

from .models import Occasion, Recipient


class OccasionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Occasion
        fields = ("id", "type", "date", "reminder_days_before", "notes", "is_active")
        read_only_fields = ("id",)


class RecipientSerializer(serializers.ModelSerializer):
    occasions = OccasionSerializer(many=True, required=False)

    class Meta:
        model = Recipient
        fields = ("id", "name", "relationship", "notes", "popia_consent", "occasions")
        read_only_fields = ("id",)

    def create(self, validated_data):
        occasions_data = validated_data.pop("occasions", [])
        recipient = Recipient.objects.create(**validated_data)
        for occasion_data in occasions_data:
            Occasion.objects.create(recipient=recipient, **occasion_data)
        return recipient