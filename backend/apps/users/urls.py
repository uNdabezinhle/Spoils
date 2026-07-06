from django.urls import path

from . import views

urlpatterns = [
    path("register/", views.register, name="register"),
    path("login/", views.login, name="login"),
    path("refresh/", views.refresh_token, name="refresh"),
    path("logout/", views.logout, name="logout"),
    path("me/", views.me, name="me"),
    path("password-reset/", views.password_reset_request, name="password-reset"),
    path("password-reset/confirm/", views.password_reset_confirm, name="password-reset-confirm"),
    path("addresses/", views.address_list, name="address-list"),
    path("addresses/<int:pk>/", views.address_detail, name="address-detail"),
]