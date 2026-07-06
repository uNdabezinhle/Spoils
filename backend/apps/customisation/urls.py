from django.urls import path

from . import views

urlpatterns = [
    path("wrapping-options/", views.wrapping_options, name="wrapping-options"),
    path("message-templates/", views.message_templates, name="message-templates"),
    path("upload-photo/", views.upload_photo, name="upload-photo"),
]