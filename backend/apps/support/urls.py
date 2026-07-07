from django.urls import path

from . import views

urlpatterns = [
    path("conversation/", views.conversation_detail, name="support-conversation"),
    path("conversation/resolve/", views.conversation_resolve, name="support-resolve"),
]