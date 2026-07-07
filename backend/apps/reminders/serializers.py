from rest_framework import serializers

from .models import Occasion, Recipient


class OccasionSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(required=False, allow_null=True)

    class Meta:
        model = Occasion
        fields = (
            "id",
            "type",
            "date",
            "reminder_days_before",
            "notes",
            "is_active",
            "snoozed_until",
            "share_with_family",
            "surprise_mode_enabled",
            "surprise_budget",
            "gift_anonymously",
            "surprise_address_id",
        )


class RecipientSerializer(serializers.ModelSerializer):
    occasions = OccasionSerializer(many=True, required=False)

    class Meta:
        model = Recipient
        fields = ("id", "name", "relationship", "notes", "popia_consent", "source", "external_id", "occasions")
        read_only_fields = ("id",)

    def create(self, validated_data):
        occasions_data = validated_data.pop("occasions", [])
        recipient = Recipient.objects.create(**validated_data)
        for occasion_data in occasions_data:
            Occasion.objects.create(recipient=recipient, **occasion_data)
        return recipient

    def update(self, instance, validated_data):
        occasions_data = validated_data.pop("occasions", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if occasions_data is not None:
            kept_ids = []
            for occasion_data in occasions_data:
                occasion_id = occasion_data.pop("id", None)
                if occasion_id:
                    occasion = instance.occasions.filter(pk=occasion_id).first()
                    if occasion:
                        for attr, value in occasion_data.items():
                            setattr(occasion, attr, value)
                        occasion.save()
                        kept_ids.append(occasion.id)
                        continue
                occasion = Occasion.objects.create(recipient=instance, **occasion_data)
                kept_ids.append(occasion.id)
            instance.occasions.exclude(pk__in=kept_ids).delete()
        return instance