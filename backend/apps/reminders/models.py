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
    snoozed_until = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.recipient.name} — {self.type}"


class ReminderLog(models.Model):
    STATUS_CHOICES = [
        ("sent", "Sent"),
        ("opened", "Opened"),
        ("acted_on", "Acted on"),
        ("snoozed", "Snoozed"),
        ("skipped", "Skipped"),
    ]

    occasion = models.ForeignKey(Occasion, on_delete=models.CASCADE, related_name="logs")
    sent_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="sent")
    skip_year = models.PositiveIntegerField(null=True, blank=True)
    chosen_product = models.ForeignKey(
        "products.Product",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reminder_picks",
    )

    class Meta:
        ordering = ["-sent_at"]


class AutoGiftProposal(models.Model):
    STATUS_CHOICES = [
        ("pending_approval", "Pending Approval"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("expired", "Expired"),
        ("ordered", "Ordered"),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="auto_gift_proposals")
    occasion = models.ForeignKey(Occasion, on_delete=models.CASCADE, related_name="auto_gift_proposals")
    subscription = models.ForeignKey(
        "subscriptions.UserSubscription",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="auto_gift_proposals",
    )
    suggested_product = models.ForeignKey(
        "products.Product",
        on_delete=models.PROTECT,
        related_name="auto_gift_proposals",
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending_approval")
    delivery_date = models.DateField()
    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="auto_gift_proposals",
    )
    expires_at = models.DateTimeField()
    approved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Auto-gift for {self.occasion} ({self.status})"