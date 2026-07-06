from django.urls import path

from . import views

urlpatterns = [
    path("recipients/", views.recipient_list, name="recipient-list"),
    path("recipients/<int:pk>/", views.recipient_detail, name="recipient-detail"),
    path("upcoming/", views.upcoming_occasions, name="upcoming-occasions"),
    path("in-app/", views.in_app_reminders, name="in-app-reminders"),
    path("calendar/", views.occasion_calendar, name="occasion-calendar"),
    path("occasions/<int:pk>/", views.occasion_detail, name="occasion-detail"),
    path("occasions/<int:pk>/suggestions/", views.occasion_suggestions, name="occasion-suggestions"),
    path("occasions/<int:pk>/snooze/", views.occasion_snooze, name="occasion-snooze"),
    path("occasions/<int:pk>/skip/", views.occasion_skip, name="occasion-skip"),
]