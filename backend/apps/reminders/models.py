from django.conf import settings
from django.db import models


class Recipient(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="recipients")
    name = models.CharField(max_length=150)
    relationship = models.CharField(max_length=50)
    notes = models.TextField(blank=True)
    popia_consent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Occasion(models.Model):
    OCCASION_TYPES = [
        ("birthday", "Birthday"),
        ("anniversary", "Anniversary"),
        ("just_because", "Just Because"),
        ("other", "Other"),
    ]
    REMINDER_DAYS = [(7, "7 days"), (14, "14 days"), (21, "21 days")]

    recipient = models.ForeignKey(Recipient, on_delete=models.CASCADE, related_name="occasions")
    type = models.CharField(max_length=30, choices=OCCASION_TYPES)
    date = models.DateField()
    reminder_days_before = models.PositiveIntegerField(default=14, choices=REMINDER_DAYS)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.recipient.name} — {self.type}"


class ReminderLog(models.Model):
    occasion = models.ForeignKey(Occasion, on_delete=models.CASCADE, related_name="logs")
    sent_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default="sent")

    class Meta:
        ordering = ["-sent_at"]