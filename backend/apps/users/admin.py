from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Address, DeviceToken, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("email", "first_name", "last_name", "phone", "is_staff", "created_at")
    search_fields = ("email", "first_name", "last_name", "phone")
    ordering = ("-created_at",)
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Spoil Profile", {"fields": ("phone",)}),
    )


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ("user", "label", "city", "province", "is_default")
    list_filter = ("province", "is_default")
    search_fields = ("user__email", "recipient_name", "city")


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "platform", "created_at")
    search_fields = ("user__email", "token")