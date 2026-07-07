from django.urls import path

from . import views

urlpatterns = [
    path("", views.group_gift_list, name="group-gift-list"),
    path("<int:pk>/", views.group_gift_detail, name="group-gift-detail"),
    path("public/<str:token>/", views.group_gift_public, name="group-gift-public"),
    path("public/<str:token>/contribute/", views.contribute_initiate, name="group-gift-contribute"),
    path("contribute/verify/", views.contribute_verify, name="group-gift-contribute-verify"),
]