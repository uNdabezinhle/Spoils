from django.apps import AppConfig


class CustomisationConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.customisation"
    label = "customisation"