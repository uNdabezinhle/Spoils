import os
import uuid

from django.conf import settings
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
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


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def upload_photo(request):
    photo = request.FILES.get("photo")
    if not photo:
        return Response({"detail": "No photo uploaded."}, status=status.HTTP_400_BAD_REQUEST)

    if photo.size > 5 * 1024 * 1024:
        return Response({"detail": "Photo must be under 5MB."}, status=status.HTTP_400_BAD_REQUEST)

    allowed = {"image/jpeg", "image/png", "image/webp", "image/jpg"}
    if photo.content_type not in allowed:
        return Response({"detail": "Only JPEG, PNG, and WebP images are allowed."}, status=400)

    if settings.CLOUDINARY_CLOUD_NAME:
        import cloudinary.uploader

        result = cloudinary.uploader.upload(
            photo,
            folder="spoil/customisations",
            transformation={"width": 800, "crop": "limit"},
        )
        return Response({"photo_url": result["secure_url"]})

    ext = os.path.splitext(photo.name)[1] or ".jpg"
    filename = f"{uuid.uuid4().hex}{ext}"
    upload_dir = os.path.join(str(settings.MEDIA_ROOT), "customisations")
    os.makedirs(upload_dir, exist_ok=True)
    filepath = os.path.join(upload_dir, filename)
    with open(filepath, "wb+") as dest:
        for chunk in photo.chunks():
            dest.write(chunk)

    photo_url = request.build_absolute_uri(settings.MEDIA_URL + f"customisations/{filename}")
    return Response({"photo_url": photo_url})