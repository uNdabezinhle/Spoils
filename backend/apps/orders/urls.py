from django.urls import path

from . import views

urlpatterns = [
    path("cart/", views.cart_detail, name="cart-detail"),
    path("cart/items/", views.cart_add_item, name="cart-add-item"),
    path("cart/items/<int:pk>/", views.cart_item_detail, name="cart-item-detail"),
    path("cart/clear/", views.cart_clear, name="cart-clear"),
    path("checkout/preview/", views.checkout_preview, name="checkout-preview"),
    path("checkout/initiate/", views.checkout_initiate, name="checkout-initiate"),
    path("checkout/verify/", views.checkout_verify, name="checkout-verify"),
    path("paystack/webhook/", views.paystack_webhook, name="paystack-webhook"),
    path("", views.order_list, name="order-list"),
    path("<int:pk>/", views.order_detail, name="order-detail"),
    path("<int:pk>/receipt/", views.order_receipt, name="order-receipt"),
    path("<int:pk>/reorder/", views.order_reorder, name="order-reorder"),
]