from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from apps.products.models import MessageTemplate, WrappingOption


@api_view(["GET"])
@permission_classes([AllowAny])
def wrapping_options(request):
    options = WrappingOption.objects.filter(is_active=True)
    return Response(
        [
            {
                "id": o.id,
                "name": o.name,
                "ribbon_color": o.ribbon_color,
                "price": str(o.price),
                "image_url": o.image_url,
            }
            for o in options
        ]
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def message_templates(request):
    occasion = request.query_params.get("occasion")
    qs = MessageTemplate.objects.filter(is_active=True)
    if occasion:
        qs = qs.filter(occasion=occasion)
    return Response(
        [{"id": t.id, "occasion": t.occasion, "title": t.title, "message": t.message} for t in qs]
    )