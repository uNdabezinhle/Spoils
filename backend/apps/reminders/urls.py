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
    path("occasions/<int:pk>/pending-gift/", views.occasion_pending_gift, name="occasion-pending-gift"),
    path("occasions/<int:pk>/approve-gift/", views.occasion_approve_gift, name="occasion-approve-gift"),
    path("occasions/<int:pk>/reject-gift/", views.occasion_reject_gift, name="occasion-reject-gift"),
    path("occasions/<int:pk>/surprise-settings/", views.occasion_surprise_settings, name="occasion-surprise-settings"),
    path("import/contacts/", views.import_contacts, name="import-contacts"),
    path("import/calendar/", views.import_calendar, name="import-calendar"),
    path("family/", views.family_group, name="family-group"),
    path("family/join/", views.family_join, name="family-join"),
    path("family/calendar/", views.family_calendar, name="family-calendar"),
]