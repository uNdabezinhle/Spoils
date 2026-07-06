from django.contrib import admin

from .models import SubscriptionPlan, UserSubscription


@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ("name", "model_type", "price_monthly", "sort_order", "is_active")
    list_editable = ("sort_order", "is_active")
    list_filter = ("model_type", "is_active")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(UserSubscription)
class UserSubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "plan", "status", "recipient_name", "next_billing_date", "started_at")
    list_filter = ("status", "plan")
    search_fields = ("user__email", "recipient_name")