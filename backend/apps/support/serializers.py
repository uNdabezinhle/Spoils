from rest_framework import serializers

from .models import SupportConversation, SupportMessage


class SupportMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportMessage
        fields = ("id", "sender_type", "body", "read_at", "created_at")


class SupportConversationSerializer(serializers.ModelSerializer):
    messages = SupportMessageSerializer(many=True, read_only=True)
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = SupportConversation
        fields = ("id", "subject", "status", "last_message_at", "created_at", "messages", "unread_count")

    def get_unread_count(self, obj) -> int:
        return obj.messages.filter(sender_type="agent", read_at__isnull=True).count()