from django.contrib import admin

from .models import GroupGift, GroupGiftContribution


class GroupGiftContributionInline(admin.TabularInline):
    model = GroupGiftContribution
    extra = 0
    readonly_fields = ("contributor_name", "contributor_email", "amount", "status", "paystack_reference", "created_at")


@admin.register(GroupGift)
class GroupGiftAdmin(admin.ModelAdmin):
    list_display = ("title", "organizer", "target_amount", "amount_collected", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("title", "organizer__email", "share_token")
    inlines = [GroupGiftContributionInline]


@admin.register(GroupGiftContribution)
class GroupGiftContributionAdmin(admin.ModelAdmin):
    list_display = ("group_gift", "contributor_name", "amount", "status", "created_at")
    list_filter = ("status",)