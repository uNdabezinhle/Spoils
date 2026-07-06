from django.contrib import admin

from .models import Occasion, Recipient, ReminderLog


class OccasionInline(admin.TabularInline):
    model = Occasion
    extra = 0


@admin.register(Recipient)
class RecipientAdmin(admin.ModelAdmin):
    list_display = ("name", "user", "relationship", "popia_consent", "created_at")
    search_fields = ("name", "user__email")
    inlines = [OccasionInline]


@admin.register(Occasion)
class OccasionAdmin(admin.ModelAdmin):
    list_display = ("recipient", "type", "date", "reminder_days_before", "is_active")
    list_filter = ("type", "is_active")


@admin.register(ReminderLog)
class ReminderLogAdmin(admin.ModelAdmin):
    list_display = ("occasion", "sent_at", "status")