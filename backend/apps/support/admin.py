from django.contrib import admin
from django.utils import timezone

from apps.reminders.services.notifications import send_push_notification

from .models import SupportConversation, SupportMessage


class SupportMessageInline(admin.TabularInline):
    model = SupportMessage
    extra = 1
    fields = ("sender_type", "body", "created_at")
    readonly_fields = ("created_at",)


@admin.register(SupportConversation)
class SupportConversationAdmin(admin.ModelAdmin):
    list_display = ("user", "subject", "status", "last_message_at")
    list_filter = ("status",)
    search_fields = ("user__email", "subject")
    inlines = [SupportMessageInline]

    def save_formset(self, request, form, formset, change):
        instances = formset.save(commit=False)
        for instance in instances:
            if isinstance(instance, SupportMessage) and instance.sender_type == "agent" and not instance.pk:
                instance.read_at = None
            instance.save()
            if isinstance(instance, SupportMessage) and instance.sender_type == "agent":
                conversation = instance.conversation
                conversation.last_message_at = timezone.now()
                conversation.save(update_fields=["last_message_at"])
                send_push_notification(
                    user=conversation.user,
                    title="Spoils support replied",
                    body=instance.body[:120],
                    data={"type": "support_message", "conversation_id": str(conversation.id)},
                )
        formset.save_m2m()