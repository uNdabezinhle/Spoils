from django.contrib import admin

from .models import Category, MessageTemplate, Product, WrappingOption


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "sort_order", "is_active")
    list_editable = ("sort_order", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "occasion",
        "base_price",
        "is_featured",
        "is_popular",
        "is_active",
    )
    list_editable = ("is_featured", "is_popular", "is_active")
    list_filter = ("category", "occasion", "is_featured", "is_popular", "is_active")
    search_fields = ("name", "description", "slug")
    prepopulated_fields = {"slug": ("name",)}
    readonly_fields = ("created_at",)
    fieldsets = (
        (None, {"fields": ("name", "slug", "category", "occasion", "description", "base_price", "image_url", "delivery_info")}),
        ("Visibility", {"fields": ("is_featured", "is_popular", "is_active")}),
        ("Timestamps", {"fields": ("created_at",)}),
    )


@admin.register(WrappingOption)
class WrappingOptionAdmin(admin.ModelAdmin):
    list_display = ("name", "ribbon_color", "price", "is_active")
    list_editable = ("is_active",)
    list_filter = ("is_active",)


@admin.register(MessageTemplate)
class MessageTemplateAdmin(admin.ModelAdmin):
    list_display = ("title", "occasion", "is_active")
    list_filter = ("occasion", "is_active")
    search_fields = ("title", "message")