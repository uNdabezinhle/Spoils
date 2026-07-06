from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import FAQ, StaticPage


@api_view(["GET"])
@permission_classes([AllowAny])
def faq_list(request):
    faqs = FAQ.objects.filter(is_active=True)
    return Response([{"id": f.id, "question": f.question, "answer": f.answer} for f in faqs])


@api_view(["GET"])
@permission_classes([AllowAny])
def static_page(request, page_type):
    try:
        page = StaticPage.objects.get(page_type=page_type)
    except StaticPage.DoesNotExist:
        return Response({"detail": "Page not found."}, status=404)
    return Response({"page_type": page.page_type, "title": page.title, "content": page.content})