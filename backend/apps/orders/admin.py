from django.contrib import admin

from .models import Cart, CartItem, Order, OrderItem, PromoCode


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "status", "total_amount", "delivery_date", "created_at")
    list_filter = ("status", "delivery_type")
    search_fields = ("user__email", "paystack_reference")
    inlines = [OrderItemInline]


@admin.register(PromoCode)
class PromoCodeAdmin(admin.ModelAdmin):
    list_display = ("code", "discount_percent", "is_active", "expires_at")


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ("user", "updated_at")


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ("cart", "product", "quantity")