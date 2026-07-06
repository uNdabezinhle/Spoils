from django.urls import path

from . import views

urlpatterns = [
    path("recipients/", views.recipient_list, name="recipient-list"),
    path("upcoming/", views.upcoming_occasions, name="upcoming-occasions"),
]