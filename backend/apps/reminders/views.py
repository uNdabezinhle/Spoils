from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Occasion, Recipient
from .serializers import RecipientSerializer


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
            "recipient_name": o.recipient.name,
            "type": o.type,
            "date": o.date.isoformat(),
            "reminder_days_before": o.reminder_days_before,
        }
        for o in occasions
    ]
    return Response(data)