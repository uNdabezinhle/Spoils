from django.urls import path

from . import views

urlpatterns = [
    path("categories/", views.category_list, name="category-list"),
    path("", views.product_list, name="product-list"),
    path("<slug:slug>/", views.product_detail, name="product-detail"),
]