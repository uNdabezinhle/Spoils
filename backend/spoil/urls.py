from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.contrib.admin.views.decorators import staff_member_required
from django.http import JsonResponse
from django.urls import include, path

from . import admin as spoil_admin  # noqa: F401 — registers site branding
from .admin_dashboard import analytics_dashboard
from .analytics_views import analytics_overview


def health_check(_request):
    return JsonResponse({"status": "ok", "app": "Spoils", "tagline": "Spoil them properly."})


urlpatterns = [
    path("admin/analytics/", staff_member_required(analytics_dashboard), name="admin-analytics"),
    path("admin/", admin.site.urls),
    path("api/health/", health_check),
    path("api/v1/auth/", include("apps.users.urls")),
    path("api/v1/products/", include("apps.products.urls")),
    path("api/v1/orders/", include("apps.orders.urls")),
    path("api/v1/customisation/", include("apps.customisation.urls")),
    path("api/v1/reminders/", include("apps.reminders.urls")),
    path("api/v1/content/", include("apps.content.urls")),
    path("api/v1/subscriptions/", include("apps.subscriptions.urls")),
    path("api/v1/analytics/overview/", analytics_overview, name="analytics-overview"),
    path("api/v1/loyalty/", include("apps.loyalty.urls")),
    path("api/v1/group-gifts/", include("apps.group_gifts.urls")),
    path("api/v1/support/", include("apps.support.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)