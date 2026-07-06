from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import render

from .analytics import get_analytics_overview


@staff_member_required
def analytics_dashboard(request):
    overview = get_analytics_overview()
    return render(
        request,
        "admin/analytics_dashboard.html",
        {
            "title": "Analytics overview",
            "overview": overview,
        },
    )