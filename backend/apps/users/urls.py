from django.urls import path

from . import views

urlpatterns = [
    path("register/", views.register, name="register"),
    path("login/", views.login, name="login"),
    path("google/", views.google_login, name="google-login"),
    path("apple/", views.apple_login, name="apple-login"),
    path("me/avatar/", views.upload_avatar, name="upload-avatar"),
    path("refresh/", views.refresh_token, name="refresh"),
    path("logout/", views.logout, name="logout"),
    path("me/export/", views.me_export, name="me-export"),
    path("me/delete/", views.me_delete, name="me-delete"),
    path("me/", views.me, name="me"),
    path("password-reset/", views.password_reset_request, name="password-reset"),
    path("password-reset/confirm/", views.password_reset_confirm, name="password-reset-confirm"),
    path("addresses/", views.address_list, name="address-list"),
    path("addresses/<int:pk>/", views.address_detail, name="address-detail"),
    path("device-token/", views.device_token, name="device-token"),
]