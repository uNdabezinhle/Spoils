from django.urls import path

from . import views

urlpatterns = [
    path("me/", views.loyalty_me, name="loyalty-me"),
    path("history/", views.loyalty_history, name="loyalty-history"),
    path("preview-redeem/", views.loyalty_preview_redeem, name="loyalty-preview-redeem"),
]