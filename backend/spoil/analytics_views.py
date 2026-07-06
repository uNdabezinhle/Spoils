from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response

from .analytics import get_analytics_overview


@api_view(["GET"])
@permission_classes([IsAdminUser])
def analytics_overview(request):
    return Response(get_analytics_overview())