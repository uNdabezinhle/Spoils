from django.utils import timezone

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Occasion, Recipient
from .serializers import RecipientSerializer


def _user_recipient(user, pk):
    try:
        return Recipient.objects.prefetch_related("occasions").get(pk=pk, user=user)
    except Recipient.DoesNotExist:
        return None


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def recipient_list(request):
    if request.method == "GET":
        recipients = Recipient.objects.filter(user=request.user).prefetch_related("occasions")
        return Response(RecipientSerializer(recipients, many=True).data)
    serializer = RecipientSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save(user=request.user)
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def recipient_detail(request, pk):
    recipient = _user_recipient(request.user, pk)
    if not recipient:
        return Response({"detail": "Recipient not found."}, status=status.HTTP_404_NOT_FOUND)

    if request.method == "GET":
        return Response(RecipientSerializer(recipient).data)

    if request.method == "DELETE":
        recipient.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = RecipientSerializer(recipient, data=request.data, partial=True)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def upcoming_occasions(request):
    occasions = (
        Occasion.objects.filter(recipient__user=request.user, is_active=True)
        .select_related("recipient")
        .order_by("date")[:20]
    )
    data = [
        {
            "id": o.id,
            "recipient_id": o.recipient_id,
            "recipient_name": o.recipient.name,
            "relationship": o.recipient.relationship,
            "type": o.type,
            "type_label": o.get_type_display(),
            "date": o.date.isoformat(),
            "reminder_days_before": o.reminder_days_before,
            "days_until": (o.date - timezone.localdate()).days,
        }
        for o in occasions
    ]
    return Response(data)