from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import Address, DeviceToken, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ("email", "first_name", "last_name", "phone", "is_staff", "is_active", "created_at")
    list_filter = ("is_staff", "is_active", "created_at")
    search_fields = ("email", "first_name", "last_name", "phone")
    ordering = ("-created_at",)
    readonly_fields = ("created_at", "updated_at", "last_login", "date_joined")
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Spoil profile", {"fields": ("phone", "created_at", "updated_at")}),
    )


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ("user", "label", "recipient_name", "city", "province", "is_default")
    list_filter = ("province", "is_default")
    search_fields = ("user__email", "recipient_name", "city", "street_address")


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "platform", "created_at")
    search_fields = ("user__email", "token")
    readonly_fields = ("created_at",)