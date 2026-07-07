from django.contrib import admin

from .models import AutoGiftProposal, FamilyGroup, FamilyMembership, Occasion, Recipient, ReminderLog


class OccasionInline(admin.TabularInline):
    model = Occasion
    extra = 0


@admin.register(Recipient)
class RecipientAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "relationship", "popia_consent", "created_at")
    list_filter = ("popia_consent", "relationship")
    search_fields = ("name", "user__email", "relationship")
    inlines = [OccasionInline]
    readonly_fields = ("created_at",)


@admin.register(Occasion)
class OccasionAdmin(admin.ModelAdmin):
    list_display = ("recipient", "type", "date", "reminder_days_before", "is_active")
    list_filter = ("type", "is_active", "reminder_days_before")
    search_fields = ("recipient__name", "recipient__user__email")
    date_hierarchy = "date"


@admin.register(ReminderLog)
class ReminderLogAdmin(admin.ModelAdmin):
    list_display = ("occasion", "sent_at", "status")
    list_filter = ("status", "sent_at")
    readonly_fields = ("occasion", "sent_at", "status")


@admin.register(FamilyGroup)
class FamilyGroupAdmin(admin.ModelAdmin):
    list_display = ("name", "owner", "invite_code", "created_at")
    search_fields = ("name", "owner__email", "invite_code")


@admin.register(FamilyMembership)
class FamilyMembershipAdmin(admin.ModelAdmin):
    list_display = ("group", "user", "role", "joined_at")
    list_filter = ("role",)


@admin.register(AutoGiftProposal)
class AutoGiftProposalAdmin(admin.ModelAdmin):
    list_display = ("occasion", "user", "status", "delivery_date", "expires_at", "created_at")
    list_filter = ("status", "delivery_date")
    search_fields = ("user__email", "occasion__recipient__name")
    readonly_fields = ("created_at", "approved_at")