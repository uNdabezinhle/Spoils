from django.urls import path

from . import views

urlpatterns = [
    path("faq/", views.faq_list, name="faq-list"),
    path("pages/<str:page_type>/", views.static_page, name="static-page"),
]