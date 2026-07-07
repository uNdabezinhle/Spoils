from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.reminders.services.notifications import send_push_notification

from .models import SupportConversation, SupportMessage
from .serializers import SupportConversationSerializer, SupportMessageSerializer


def _get_or_create_open_conversation(user) -> SupportConversation:
    conversation = (
        SupportConversation.objects.filter(user=user, status="open").order_by("-last_message_at").first()
    )
    if conversation:
        return conversation
    conversation = SupportConversation.objects.create(user=user)
    SupportMessage.objects.create(
        conversation=conversation,
        sender_type="system",
        body="Hi! A Spoils support agent will reply shortly. How can we help you spoil someone properly?",
    )
    return conversation


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def conversation_detail(request):
    conversation = _get_or_create_open_conversation(request.user)
    if request.method == "GET":
        since = request.query_params.get("since")
        data = SupportConversationSerializer(conversation).data
        if since:
            since_dt = parse_datetime(since)
            if since_dt:
                data["messages"] = [
                    m
                    for m in data["messages"]
                    if parse_datetime(m["created_at"]) and parse_datetime(m["created_at"]) > since_dt
                ]
        conversation.messages.filter(sender_type="agent", read_at__isnull=True).update(read_at=timezone.now())
        return Response(data)

    body = request.data.get("body", "").strip()
    if not body:
        return Response({"detail": "body is required."}, status=400)

    message = SupportMessage.objects.create(conversation=conversation, sender_type="user", body=body)
    conversation.last_message_at = timezone.now()
    conversation.save(update_fields=["last_message_at"])
    from .broadcast import broadcast_support_message

    payload = SupportMessageSerializer(message).data
    broadcast_support_message(user_id=request.user.id, payload=payload)
    return Response(payload, status=status.HTTP_201_CREATED)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def conversation_resolve(request):
    conversation = _get_or_create_open_conversation(request.user)
    conversation.status = "resolved"
    conversation.save(update_fields=["status"])
    return Response({"detail": "Conversation resolved."})