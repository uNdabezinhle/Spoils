from django.urls import path

from . import views

urlpatterns = [
    path("plans/", views.plan_list, name="subscription-plans"),
    path("me/", views.my_subscriptions, name="my-subscriptions"),
    path("subscribe/", views.subscribe, name="subscribe"),
    path("subscribe/verify/", views.subscribe_verify, name="subscribe-verify"),
    path("<int:pk>/cancel/", views.cancel_subscription, name="cancel-subscription"),
]