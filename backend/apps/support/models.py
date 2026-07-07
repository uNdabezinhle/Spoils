from django.conf import settings
from django.db import models


class SupportConversation(models.Model):
    STATUS_CHOICES = [
        ("open", "Open"),
        ("resolved", "Resolved"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="support_conversations")
    subject = models.CharField(max_length=200, default="General support")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="open")
    last_message_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-last_message_at"]

    def __str__(self):
        return f"{self.user.email} — {self.subject}"


class SupportMessage(models.Model):
    SENDER_CHOICES = [
        ("user", "User"),
        ("agent", "Agent"),
        ("system", "System"),
    ]

    conversation = models.ForeignKey(SupportConversation, on_delete=models.CASCADE, related_name="messages")
    sender_type = models.CharField(max_length=10, choices=SENDER_CHOICES)
    body = models.TextField()
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.sender_type}: {self.body[:40]}"