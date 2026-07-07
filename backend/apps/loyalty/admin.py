from django.contrib import admin

from .models import LoyaltyAccount, PointsLedgerEntry


class PointsLedgerEntryInline(admin.TabularInline):
    model = PointsLedgerEntry
    extra = 0
    readonly_fields = ("entry_type", "points", "balance_after", "description", "order", "created_at")


@admin.register(LoyaltyAccount)
class LoyaltyAccountAdmin(admin.ModelAdmin):
    list_display = ("user", "balance", "lifetime_earned", "updated_at")
    search_fields = ("user__email",)
    inlines = [PointsLedgerEntryInline]


@admin.register(PointsLedgerEntry)
class PointsLedgerEntryAdmin(admin.ModelAdmin):
    list_display = ("account", "entry_type", "points", "balance_after", "created_at")
    list_filter = ("entry_type",)