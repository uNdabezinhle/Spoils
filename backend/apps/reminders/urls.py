from django.urls import path

from . import views

urlpatterns = [
    path("recipients/", views.recipient_list, name="recipient-list"),
    path("recipients/<int:pk>/", views.recipient_detail, name="recipient-detail"),
    path("upcoming/", views.upcoming_occasions, name="upcoming-occasions"),
]