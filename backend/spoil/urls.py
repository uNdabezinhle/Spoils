from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path

from . import admin as spoil_admin  # noqa: F401 — registers site branding


def health_check(_request):
    return JsonResponse({"status": "ok", "app": "Spoils", "tagline": "Spoil them properly."})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health_check),
    path("api/v1/auth/", include("apps.users.urls")),
    path("api/v1/products/", include("apps.products.urls")),
    path("api/v1/orders/", include("apps.orders.urls")),
    path("api/v1/customisation/", include("apps.customisation.urls")),
    path("api/v1/reminders/", include("apps.reminders.urls")),
    path("api/v1/content/", include("apps.content.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)