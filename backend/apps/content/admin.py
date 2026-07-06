from django.contrib import admin

from .models import FAQ, StaticPage


@admin.register(StaticPage)
class StaticPageAdmin(admin.ModelAdmin):
    list_display = ("page_type", "title", "updated_at")
    search_fields = ("title", "content")
    readonly_fields = ("updated_at",)


@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ("question", "sort_order", "is_active")
    list_editable = ("sort_order", "is_active")
    list_filter = ("is_active",)
    search_fields = ("question", "answer")