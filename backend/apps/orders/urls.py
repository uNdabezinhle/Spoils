from django.urls import path

from . import views

urlpatterns = [
    path("cart/", views.cart_detail, name="cart-detail"),
    path("", views.order_list, name="order-list"),
]