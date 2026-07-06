from django.contrib import admin, messages

from .models import Cart, CartItem, Order, OrderItem, PromoCode
from .services.notifications import notify_order_status_change


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ("product", "quantity", "unit_price", "customisation_details")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "status",
        "total_amount",
        "delivery_type",
        "delivery_date",
        "created_at",
    )
    list_filter = ("status", "delivery_type", "created_at")
    search_fields = ("user__email", "paystack_reference", "id")
    date_hierarchy = "created_at"
    readonly_fields = (
        "user",
        "total_amount",
        "delivery_address",
        "paystack_reference",
        "promo_code",
        "created_at",
        "updated_at",
    )
    inlines = [OrderItemInline]
    actions = [
        "mark_processing",
        "mark_shipped",
        "mark_delivered",
        "mark_cancelled",
    ]
    fieldsets = (
        (None, {"fields": ("user", "status", "total_amount", "promo_code")}),
        ("Delivery", {"fields": ("delivery_type", "delivery_date", "delivery_address")}),
        ("Payment", {"fields": ("paystack_reference",)}),
        ("Timestamps", {"fields": ("created_at", "updated_at")}),
    )

    def save_model(self, request, obj, form, change):
        previous_status = None
        if change and obj.pk:
            previous_status = Order.objects.filter(pk=obj.pk).values_list("status", flat=True).first()
        super().save_model(request, obj, form, change)
        if change:
            notify_order_status_change(order=obj, previous_status=previous_status)

    @admin.action(description="Mark selected as Processing")
    def mark_processing(self, request, queryset):
        updated = self._transition_status(queryset, "processing", ["paid", "processing"])
        self.message_user(request, f"{updated} order(s) marked as processing.", messages.SUCCESS)

    @admin.action(description="Mark selected as Shipped")
    def mark_shipped(self, request, queryset):
        updated = self._transition_status(queryset, "shipped", ["paid", "processing", "shipped"])
        self.message_user(request, f"{updated} order(s) marked as shipped.", messages.SUCCESS)

    @admin.action(description="Mark selected as Delivered")
    def mark_delivered(self, request, queryset):
        updated = self._transition_status(
            queryset, "delivered", ["paid", "processing", "shipped", "delivered"]
        )
        self.message_user(request, f"{updated} order(s) marked as delivered.", messages.SUCCESS)

    @admin.action(description="Mark selected as Cancelled")
    def mark_cancelled(self, request, queryset):
        updated = self._transition_status(queryset, "cancelled", exclude_status="cancelled")
        self.message_user(request, f"{updated} order(s) cancelled.", messages.WARNING)

    def _transition_status(self, queryset, new_status, allowed=None, exclude_status=None):
        updated = 0
        for order in queryset.select_related("user"):
            if exclude_status and order.status == exclude_status:
                continue
            if allowed is not None and order.status not in allowed:
                continue
            previous = order.status
            if previous == new_status:
                continue
            order.status = new_status
            order.save(update_fields=["status", "updated_at"])
            notify_order_status_change(order=order, previous_status=previous)
            updated += 1
        return updated


@admin.register(PromoCode)
class PromoCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "discount_percent", "is_active", "expires_at")
    list_filter = ("is_active",)
    search_fields = ("code",)


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ("user", "updated_at")
    search_fields = ("user__email",)


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ("cart", "product", "quantity")
    search_fields = ("cart__user__email", "product__name")