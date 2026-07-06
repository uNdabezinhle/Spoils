from django.contrib import admin

from .models import Category, MessageTemplate, Product, WrappingOption


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "sort_order", "is_active")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "base_price", "is_featured", "is_popular", "is_active")
    list_filter = ("category", "is_featured", "is_popular", "is_active")
    search_fields = ("name", "description")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(WrappingOption)
class WrappingOptionAdmin(admin.ModelAdmin):
    list_display = ("name", "ribbon_color", "price", "is_active")


@admin.register(MessageTemplate)
class MessageTemplateAdmin(admin.ModelAdmin):
    list_display = ("title", "occasion", "is_active")
    list_filter = ("occasion", "is_active")